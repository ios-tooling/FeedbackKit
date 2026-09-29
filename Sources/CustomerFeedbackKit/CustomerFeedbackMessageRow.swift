import SwiftUI

struct CustomerFeedbackMessageRow: View {
    let message: CustomerFeedbackMessage
    let session: CustomerFeedbackSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.role == "staff" ? "Team" : "You").font(.headline)
                .onScrollVisibilityChange(threshold: 0.5) { visible = $0 }
            Text(message.date, format: .dateTime).font(.caption).foregroundStyle(.secondary)
            Text(message.text).textSelection(.enabled)
            ForEach(message.attachments, id: \.self) { id in
                CustomerFeedbackAttachment(id: id, session: session)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: visible && scenePhase == .active) {
            guard visible, scenePhase == .active else { return }
            // A brief dwell avoids marking a reply read while scrolling straight past it.
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            await session.viewed(message)
        }
    }
}

private struct CustomerFeedbackAttachment: View {
    let id: UUID
    let session: CustomerFeedbackSession
    @State private var data: Data?
    @State private var hasError = false
    @State private var attempt = 0
    @State private var expanded = false
    var body: some View {
        Group {
            if let data {
                Button { expanded = true } label: {
                    FeedbackImagePreview(data: data).frame(maxHeight: 200)
                }.buttonStyle(.plain).accessibilityLabel("View attached screenshot")
            } else if hasError {
                Button("Retry Screenshot") { attempt += 1 }
            } else { ProgressView("Loading screenshot…") }
        }
        .task(id: attempt) {
            hasError = false
            do { data = try await session.image(id) } catch { hasError = true }
        }
        .sheet(isPresented: $expanded) {
            NavigationStack {
                if let data { FeedbackImagePreview(data: data).padding() }
            }.toolbar { Button("Done") { expanded = false } }
        }
    }
}
private struct FeedbackImagePreview: View {
    let data: Data
    var body: some View {
        #if os(iOS)
        if let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Attached screenshot") }
        #else
        if let image = NSImage(data: data) { Image(nsImage: image).resizable().scaledToFit().accessibilityLabel("Attached screenshot") }
        #endif
    }
}
