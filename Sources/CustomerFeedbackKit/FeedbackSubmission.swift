import Foundation

/// A text-first report. Only images explicitly selected by the reader are included.
public struct FeedbackSubmission: Sendable {
    public let id: UUID
    public let category: FeedbackCategory
    public let text: String
    public let screenshots: [Data]

    public init(id: UUID, category: FeedbackCategory, text: String, screenshots: [Data]) {
        self.id = id
        self.category = category
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.screenshots = screenshots
    }

    public static let maximumTextLength = 10_000
    public static let maximumScreenshots = 3
    public static let maximumImageBytes = 1_024 * 1_024

    public var isValid: Bool {
        !text.isEmpty && text.utf16.count <= Self.maximumTextLength &&
        screenshots.count <= Self.maximumScreenshots &&
        screenshots.allSatisfy { !$0.isEmpty && $0.count <= Self.maximumImageBytes }
    }
}
