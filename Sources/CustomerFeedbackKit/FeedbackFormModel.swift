import SwiftUI

@MainActor @Observable final class FeedbackFormModel {
    var category: FeedbackCategory = .bug { didSet { id = UUID() } }
    var text = "" { didSet { id = UUID() } }
    var screenshots: [FeedbackScreenshot] = [] { didSet { id = UUID() } }
    private var id = UUID()
    var sending = false
    var loadingImages = false
    var sent = false
    var error: String?

    var submission: FeedbackSubmission {
        FeedbackSubmission(id: id, category: category, text: text, screenshots: screenshots.map(\.data))
    }

    func send(using submit: @MainActor (FeedbackSubmission) async throws -> Void) async {
        guard !sending, !loadingImages, submission.isValid else { return }
        sending = true
        error = nil
        defer { sending = false }
        do {
            try await submit(submission)
            sent = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct FeedbackScreenshot: Identifiable {
    let id = UUID()
    let data: Data
}
