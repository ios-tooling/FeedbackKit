//
//  FeedbackEditorScreen.swift
//  FeedbackKit
//
//  Full-screen editor presented over the frozen capture: annotate, comment, categorize,
//  and send.
//

#if canImport(UIKit) && !os(watchOS)
import SwiftUI
import PencilKit

struct FeedbackEditorScreen: View {
	let draft: FeedbackDraft
	@State private var controller = FeedbackController.shared
	@State private var canvas = PKCanvasView()
	@State private var store = MarkupStore()
	@State private var displaySize: CGSize = .zero
	@State private var comment = ""
	@State private var category: FeedbackCategory = .bug
	@State private var commentExpanded = false
	@State private var includeScreenshot = true

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				if includeScreenshot {
					MarkupToolbar(store: store)
					MarkupCanvasView(image: draft.originalImage, canvas: canvas, store: store, isCommenting: commentExpanded, displaySize: $displaySize)
					if commentExpanded { CommentField(text: $comment) }
				} else {
					CommentField(text: $comment)
					Spacer(minLength: 0)
				}
			}
			.onChange(of: store.tool) { if commentExpanded { withAnimation { commentExpanded = false } } }
			.navigationTitle("Feedback")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel", role: .cancel) { controller.cancel() }
				}
				ToolbarItem(placement: .principal) {
					Picker("Category", selection: $category) {
						ForEach(FeedbackCategory.allCases, id: \.self) { category in
							Label(category.displayName, systemImage: category.symbolName).tag(category)
						}
					}
					.pickerStyle(.menu)
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button(includeScreenshot ? "Hide screenshot" : "Add screenshot", systemImage: includeScreenshot ? "photo" : "photo.badge.plus") {
						withAnimation { includeScreenshot.toggle() }
					}
				}
				if includeScreenshot {
					ToolbarItem(placement: .topBarTrailing) {
						Button("Comment", systemImage: commentExpanded ? "text.bubble.fill" : "text.bubble") {
							withAnimation { commentExpanded.toggle() }
						}
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Send", action: send).disabled(!canSend)
				}
			}
			.toolbarBackground(.visible, for: .navigationBar)
			.toolbarBackground(.black, for: .navigationBar)
		}
		.preferredColorScheme(.dark)
	}

	// A text-only report needs a comment; with a screenshot there is always content.
	private var canSend: Bool {
		includeScreenshot || !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	private func send() {
		let annotated = includeScreenshot
			? MarkupFlattener.flatten(base: draft.originalImage, drawing: canvas.drawing, annotations: store.annotations, displaySize: displaySize, cropRect: store.cropRect)
			: nil
		guard let report = ReportBuilder.makeReport(draft: draft, comment: comment, category: category, annotated: annotated) else {
			controller.cancel()
			return
		}
		controller.submit(report)
	}
}
#endif
