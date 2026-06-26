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
	@State private var commentExpanded = true

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				MarkupCanvasView(image: draft.originalImage, canvas: canvas, store: store, displaySize: $displaySize)
				MarkupToolbar(store: store)
				if commentExpanded { CommentField(text: $comment) }
			}
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
					Button("Comment", systemImage: commentExpanded ? "text.bubble.fill" : "text.bubble") {
						withAnimation { commentExpanded.toggle() }
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Send", action: send)
				}
			}
		}
	}

	private func send() {
		let annotated = MarkupFlattener.flatten(base: draft.originalImage, drawing: canvas.drawing, annotations: store.annotations, displaySize: displaySize)
		guard let report = ReportBuilder.makeReport(draft: draft, comment: comment, category: category, annotated: annotated) else {
			controller.cancel()
			return
		}
		controller.submit(report)
	}
}
#endif
