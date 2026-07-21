//
//  FeedbackEditorScreen.swift
//  FeedbackKit
//
//  Full-screen editor presented over the frozen capture: annotate, comment, categorize,
//  and send.
//

import SwiftUI
import CrossPlatformKit
#if canImport(UIKit)
import PencilKit
#endif

struct FeedbackEditorScreen: View {
	let draft: FeedbackDraft
	@State private var controller = FeedbackController.shared
	#if canImport(UIKit)
	@State private var canvas = PKCanvasView()
	#endif
	@State private var store = MarkupStore()
	@State private var displaySize: CGSize = .zero
	@State private var comment = ""
	@State private var category: FeedbackCategory = .bug
	@State private var commentExpanded = true
	@State private var includeScreenshot = true
	@State private var dictation = FeedbackDictation()

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				if includeScreenshot {
					MarkupToolbar(store: store)
					canvasView
					if commentExpanded { CommentField(text: $comment, dictation: dictation) }
				} else {
					CommentField(text: $comment, dictation: dictation)
					Spacer(minLength: 0)
				}
			}
			.onChange(of: store.tool) { if commentExpanded { withAnimation { commentExpanded = false } } }
			.onDisappear { Task { await dictation.stop() } }
			.navigationTitle("Feedback")
			.toolbar {
				FeedbackEditorToolbar(category: $category, includeScreenshot: $includeScreenshot,
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
		MarkupCanvasView(image: draft.originalImage, canvas: canvas, store: store, isCommenting: commentExpanded, displaySize: $displaySize)
		#else
		MarkupCanvasView(image: draft.originalImage, store: store, isCommenting: commentExpanded, displaySize: $displaySize)
		#endif
	}

	// A text-only report needs a comment; with a screenshot there is always content.
	private var canSend: Bool {
		includeScreenshot || !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	private func send() async {
		await dictation.stop()
		let annotated = includeScreenshot
			? MarkupFlattener.flatten(base: draft.originalImage, strokeImage: strokeImage, annotations: store.annotations, displaySize: displaySize, cropRect: store.cropRect)
			: nil
		guard let report = ReportBuilder.makeReport(draft: draft, comment: comment, category: category, annotated: annotated, audioData: dictation.audioData()) else {
			cancel()
			return
		}
		dictation.discard()
		controller.submit(report)
	}

	private func cancel() {
		Task {
			await dictation.stop()
			dictation.discard()
			controller.cancel()
		}
	}

	/// The freehand layer, rasterized at native resolution for the flattener.
	private var strokeImage: UXImage? {
		#if canImport(UIKit)
		guard !canvas.drawing.bounds.isEmpty, displaySize.width > 0 else { return nil }
		let pixelWidth = CGFloat(draft.originalImage.cgImageRef?.width ?? Int(draft.originalImage.size.width))
		let scale = pixelWidth / displaySize.width
		return canvas.drawing.image(from: CGRect(origin: .zero, size: displaySize), scale: scale)
		#else
		return FreehandRenderer.image(strokes: store.strokes, size: displaySize)
		#endif
	}
}
