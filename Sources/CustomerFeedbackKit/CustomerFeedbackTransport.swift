import Foundation

public enum FeedbackCategory: String, Sendable, CaseIterable { case bug, idea = "suggestion", other = "comment" }

public struct CustomerFeedbackMessage: Identifiable, Sendable, Decodable, Equatable {
    public let id: UUID
    public let sequence: Int
    public let role: String
    public let text: String
    public let category: String?
    public let createdAt: Double
    public let attachments: [UUID]
    public var date: Date { Date(timeIntervalSince1970: createdAt / 1000) }
    public init(id: UUID, sequence: Int, role: String, text: String, category: String? = nil, createdAt: Double, attachments: [UUID] = []) {
        self.id = id; self.sequence = sequence; self.role = role; self.text = text
        self.category = category; self.createdAt = createdAt; self.attachments = attachments
    }
}
public struct CustomerFeedbackConversation: Sendable, Decodable, Equatable {
    public let id: UUID
    public let generation: Int
    public let unreadCount: Int
    public init(id: UUID, generation: Int, unreadCount: Int) {
        self.id = id; self.generation = generation; self.unreadCount = unreadCount
    }
}
public struct CustomerFeedbackPage: Sendable, Decodable {
    public let conversation: CustomerFeedbackConversation?
    public let messages: [CustomerFeedbackMessage]
    public let hasMore: Bool
    public let olderCursor: Int?
    public let nextCursor: Int?
    public init(conversation: CustomerFeedbackConversation?, messages: [CustomerFeedbackMessage], hasMore: Bool = false, olderCursor: Int? = nil, nextCursor: Int? = nil) {
        self.conversation = conversation; self.messages = messages; self.hasMore = hasMore
        self.olderCursor = olderCursor; self.nextCursor = nextCursor
    }
}
public struct CustomerFeedbackQuery: Sendable {
    public let conversation: CustomerFeedbackConversation?
    public let after: Int?
    public let before: Int?
    public init(conversation: CustomerFeedbackConversation? = nil, after: Int? = nil, before: Int? = nil) {
        self.conversation = conversation; self.after = after; self.before = before
    }
}
/// A transport is bound to one account. Replace the session when that account changes.
@MainActor public protocol CustomerFeedbackTransport {
    func fetch(_ query: CustomerFeedbackQuery) async throws -> CustomerFeedbackPage
    func send(_ submission: FeedbackSubmission) async throws
    func attachment(_ id: UUID) async throws -> Data
    func markRead(conversationID: UUID, messageIDs: [UUID]) async throws
}
public enum CustomerFeedbackError: Error { case reloadRequired }
