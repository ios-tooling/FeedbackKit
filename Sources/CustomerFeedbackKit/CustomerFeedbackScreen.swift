import SwiftUI

/// A programmatic customer conversation. No developer capture gestures or diagnostics.
public struct CustomerFeedbackScreen: View {
    @Bindable private var session: CustomerFeedbackSession
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    public init(session: CustomerFeedbackSession) { self.session = session }
    public var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            Form {
                if !session.loaded {
                    Section {
                        if session.loading { ProgressView("Loading feedback…") }
                        else { Button("Retry Loading") { Task { await session.refresh() } } }
                    }
                } else {
                    if !session.messages.isEmpty {
                        Section("Conversation") {
                            if session.hasOlder {
                                Button("Load Earlier Messages") { Task { await session.loadOlder() } }
                                    .disabled(session.loading)
                            }
                            ForEach(session.messages) { message in
                                CustomerFeedbackMessageRow(message: message, session: session).id(message.id)
                            }
                        }
                    }
                    CustomerFeedbackComposer(session: session)
                }
                if let error = session.error {
                    Section {
                        Text(error).foregroundStyle(.red)
                        Button("Retry") { Task { await session.refresh() } }
                    }
                }
            }
            .onChange(of: session.messages.last?.id) { _, id in
                if let id { proxy.scrollTo(id, anchor: .top) }
            }
            .navigationTitle(session.messages.isEmpty ? "Submit Feedback" : "Feedback")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                await session.refresh()
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(15)) } catch { return }
                    await session.refresh()
                }
            }
            }
        }
    }
}
