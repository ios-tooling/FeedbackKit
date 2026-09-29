import SwiftUI

struct CustomerFeedbackComposer: View {
    @Bindable var session: CustomerFeedbackSession
    var body: some View {
        @Bindable var draft = session.draft
        Group {
            if session.messages.isEmpty {
                Section("Feedback Type") {
                    Picker("Type", selection: $draft.category) {
                        Text("Bug").tag(FeedbackCategory.bug)
                        Text("Suggestion").tag(FeedbackCategory.idea)
                        Text("General Comment").tag(FeedbackCategory.other)
                    }
                }
            }
            Section {
                CustomerFeedbackMessageField(session: session)
                Text("\(draft.text.utf16.count) / \(FeedbackSubmission.maximumTextLength)")
                    .font(.caption).foregroundStyle(.secondary)
            } header: {
                Text(session.messages.isEmpty ? "Your Feedback" : "Your Message")
            } footer: {
                Text("Your app version and operating system are included. Select only screenshots you want to share. Replies appear here.")
            }
            FeedbackAttachmentsSection(model: draft)
            if let error = draft.error { Section { Text(error).foregroundStyle(.red) } }
        }.disabled(draft.sending)
    }
}

private struct CustomerFeedbackMessageField: View {
    @Bindable var session: CustomerFeedbackSession
    var body: some View {
        @Bindable var draft = session.draft
        HStack(alignment: .bottom) {
            TextField("Write a message…", text: $draft.text, axis: .vertical)
                .lineLimit(1...6)
                .accessibilityLabel("Feedback")
                .padding(.vertical, 12)
                .padding(.leading, 12)
            Button { Task { await session.send() } } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.largeTitle)
                    .opacity(draft.sending ? 0 : 1)
                    .overlay { if draft.sending { ProgressView() } }
                    .padding(6)
            }
            .buttonStyle(.borderless)
            .disabled(!draft.submission.isValid || draft.sending || draft.loadingImages)
            .accessibilityLabel("Send Feedback")
            .accessibilityValue(draft.sending ? "Sending" : "")
        }
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 24))
    }
}
