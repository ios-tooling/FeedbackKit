//
//  FeedbackEditorScreen.swift
//  FeedbackKit
//
//  Full-screen editor presented over the frozen capture: annotate, comment, categorize,
//  and send. All draft state lives in the shared FeedbackDraftEditing.
//

import SwiftUI

struct FeedbackEditorScreen: View {
	@Bindable var editing: FeedbackDraftEditing
	@State private var controller = FeedbackController.shared
	@State private var commentExpanded = true

	private var draft: FeedbackDraft { editing.draft }

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				if editing.includeScreenshot {
					MarkupToolbar(store: editing.store)
					canvasView
					if commentExpanded { CommentField(text: $editing.comment, dictation: editing.dictation) }
				} else {
					CommentField(text: $editing.comment, dictation: editing.dictation)
					Spacer(minLength: 0)
				}
			}
			.onChange(of: editing.store.tool) { if commentExpanded { withAnimation { commentExpanded = false } } }
			.onDisappear { Task { await editing.dictation.stop() } }
			.navigationTitle("Feedback")
			.toolbar {
				FeedbackEditorToolbar(category: $editing.category, includeScreenshot: $editing.includeScreenshot,
									  commentExpanded: $commentExpanded, canSend: canSend,
									  onCancel: cancel, onSend: { Task { await send() } })
			}
			#if canImport(UIKit)
			.navigationBarTitleDisplayMode(.inline)
			.toolbarBackground(.visible, for: .navigationBar)
			.toolbarBackground(.black, for: .navigationBar)
			#endif
		}
		.preferredColorScheme(.dark)
	}

	@ViewBuilder private var canvasView: some View {
		#if canImport(UIKit)
		MarkupCanvasView(image: draft.originalImage, canvas: editing.canvas, store: editing.store, isCommenting: commentExpanded, displaySize: $editing.displaySize)
		#else
		MarkupCanvasView(image: draft.originalImage, store: editing.store, isCommenting: commentExpanded, displaySize: $editing.displaySize)
		#endif
	}

	// A text-only report needs a comment; with a screenshot there is always content.
	private var canSend: Bool {
		editing.includeScreenshot || !editing.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	private func send() async {
		await editing.dictation.stop()
		guard let report = editing.buildReport() else {
			cancel()
			return
		}
		editing.dictation.discard()
		controller.submit(report)
	}

	private func cancel() {
		Task {
			await editing.dictation.stop()
			editing.dictation.discard()
			controller.cancel()
		}
	}
}
