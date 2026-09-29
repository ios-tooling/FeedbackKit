import Foundation
import Observation

/// Keep one session per account to preserve a failed draft across presentations.
@MainActor @Observable public final class CustomerFeedbackSession {
    public private(set) var messages: [CustomerFeedbackMessage] = []
    public private(set) var conversation: CustomerFeedbackConversation?
    public private(set) var unreadCount = 0
    public private(set) var loaded = false
    public private(set) var loading = false
    public private(set) var hasOlder = false
    public private(set) var error: String?
    var draft = FeedbackFormModel()
    private let transport: any CustomerFeedbackTransport
    private var acknowledged: Set<UUID> = []
    private var reading: Set<UUID> = []
    private var valid = true
    public init(transport: any CustomerFeedbackTransport) { self.transport = transport }

    /// Immediately hides private data and ignores in-flight results after account departure.
    public func invalidate() {
        valid = false; messages = []; conversation = nil; unreadCount = 0
        draft = FeedbackFormModel(); acknowledged = []; reading = []; loaded = false
    }
    public func refresh() async { await load(older: false) }
    public func loadOlder() async { await load(older: true) }
    private func load(older: Bool) async {
        guard valid, !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let query = CustomerFeedbackQuery(conversation: conversation,
                after: older ? nil : messages.last?.sequence, before: older ? messages.first?.sequence : nil)
            var page: CustomerFeedbackPage
            do { page = try await transport.fetch(query) }
            catch CustomerFeedbackError.reloadRequired { page = try await transport.fetch(.init()) }
            guard valid else { return }
            if conversation?.id != page.conversation?.id || conversation?.generation != page.conversation?.generation {
                messages = []; acknowledged = []; hasOlder = page.hasMore
            }
            let firstLoad = !loaded || messages.isEmpty
            merge(page)
            if older || firstLoad { hasOlder = page.hasMore }
            // Drain deltas in bounded pages. The next poll resumes from the last merged message.
            if !older && !firstLoad {
                for _ in 0..<10 where page.hasMore {
                    page = try await transport.fetch(.init(conversation: conversation, after: messages.last?.sequence))
                    guard valid else { return }; merge(page)
                }
            }
            loaded = true; error = nil
        } catch { if valid { self.error = error.localizedDescription } }
    }
    private func merge(_ page: CustomerFeedbackPage) {
        conversation = page.conversation; unreadCount = page.conversation?.unreadCount ?? 0
        var byID = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        for message in page.messages { byID[message.id] = message }
        messages = byID.values.sorted { $0.sequence < $1.sequence }
    }
    func send() async {
        guard valid else { return }
        let sendingDraft = draft
        await sendingDraft.send { [self] submission in try await transport.send(submission) }
        guard valid else { return }
        if sendingDraft.sent { draft = FeedbackFormModel(); await refresh() }
    }
    func viewed(_ message: CustomerFeedbackMessage) async {
        guard valid, message.role == "staff", !acknowledged.contains(message.id), !reading.contains(message.id), let conversation else { return }
        reading.insert(message.id)
        defer { reading.remove(message.id) }
        do {
            try await transport.markRead(conversationID: conversation.id, messageIDs: [message.id])
            guard valid else { return }
            acknowledged.insert(message.id)
            await refresh()
        } catch { if valid { self.error = error.localizedDescription } }
    }
    func image(_ id: UUID) async throws -> Data {
        let data = try await transport.attachment(id)
        guard valid else { throw CancellationError() }
        return data
    }
}
