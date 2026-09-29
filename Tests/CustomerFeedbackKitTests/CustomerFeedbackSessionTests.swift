import Foundation
import Testing
@testable import CustomerFeedbackKit

@MainActor private final class Transport: CustomerFeedbackTransport {
    var page = CustomerFeedbackPage(conversation: nil, messages: [])
    var sent: [FeedbackSubmission] = []
    var reads: [UUID] = []
    var failSend = false
    var fetchGate: CheckedContinuation<CustomerFeedbackPage, Never>?
    var suspendFetch = false
    func fetch(_ query: CustomerFeedbackQuery) async throws -> CustomerFeedbackPage {
        if suspendFetch { return await withCheckedContinuation { fetchGate = $0 } }
        return page
    }
    func send(_ submission: FeedbackSubmission) async throws {
        sent.append(submission)
        if failSend { throw URLError(.networkConnectionLost) }
    }
    func attachment(_ id: UUID) async throws -> Data { Data() }
    func markRead(conversationID: UUID, messageIDs: [UUID]) async throws { reads += messageIDs }
}
@MainActor @Suite struct CustomerFeedbackSessionTests {
    @Test func fetchingDoesNotReadAndOnlyViewedMessagesAreAcknowledged() async {
        let transport = Transport(), conversation = UUID()
        let first = CustomerFeedbackMessage(id: UUID(), sequence: 1, role: "staff", text: "One", createdAt: 1)
        let second = CustomerFeedbackMessage(id: UUID(), sequence: 2, role: "staff", text: "Two", createdAt: 2)
        transport.page = .init(conversation: .init(id: conversation, generation: 1, unreadCount: 2), messages: [first, second])
        let session = CustomerFeedbackSession(transport: transport)
        await session.refresh()
        #expect(session.unreadCount == 2); #expect(transport.reads.isEmpty)
        await session.viewed(first); await session.viewed(first)
        #expect(transport.reads == [first.id])
    }
    @Test func failedSendKeepsDraftAndRetryIdentity() async {
        let transport = Transport(), session = CustomerFeedbackSession(transport: Transport())
        let model = CustomerFeedbackSession(transport: transport)
        model.draft.text = "Keep this"; transport.failSend = true
        await model.send()
        #expect(model.draft.text == "Keep this")
        transport.failSend = false; await model.send()
        #expect(transport.sent.count == 2)
        #expect(transport.sent[0].id == transport.sent[1].id)
        #expect(model.draft.text.isEmpty)
        session.invalidate()
    }
    @Test func accountDepartureRejectsLateHistoryAndClearsDraft() async {
        let transport = Transport(); transport.suspendFetch = true
        let session = CustomerFeedbackSession(transport: transport)
        session.draft.text = "Private"
        let task = Task { await session.refresh() }
        while transport.fetchGate == nil { await Task.yield() }
        session.invalidate()
        transport.fetchGate?.resume(returning: .init(conversation: .init(id: UUID(), generation: 1, unreadCount: 1), messages: [.init(id: UUID(), sequence: 1, role: "staff", text: "Private answer", createdAt: 1)]))
        await task.value
        #expect(session.messages.isEmpty); #expect(session.draft.text.isEmpty); #expect(session.unreadCount == 0)
    }
    @Test func changedGenerationReplacesCachedHistory() async {
        let transport = Transport(), id = UUID()
        transport.page = .init(conversation: .init(id: id, generation: 1, unreadCount: 0), messages: [.init(id: UUID(), sequence: 1, role: "customer", text: "old", createdAt: 1)])
        let session = CustomerFeedbackSession(transport: transport); await session.refresh()
        transport.page = .init(conversation: .init(id: id, generation: 2, unreadCount: 0), messages: [.init(id: UUID(), sequence: 2, role: "customer", text: "new", createdAt: 2)])
        await session.refresh(); #expect(session.messages.map(\.text) == ["new"])
    }
}
