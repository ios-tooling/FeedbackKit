//
//  FeedbackDraftEditing.swift
//  FeedbackKit
//
//  The single source of truth for the report being edited, shared between the editor page
//  and the export page: comment, category, markup, dictation, and the logic to flatten it
//  into a FeedbackReport. Lets the in-progress report show — and export — before it is sent.
//

import Foundation
import CrossPlatformKit
#if canImport(UIKit)
import PencilKit
#endif

@MainActor @Observable final class FeedbackDraftEditing {
	let draft: FeedbackDraft
	var comment = ""
	var category: FeedbackCategory = .bug
	var includeScreenshot = true
	var displaySize: CGSize = .zero

	let store = MarkupStore()
	let dictation = FeedbackDictation()
	#if canImport(UIKit)
	let canvas = PKCanvasView()
	#endif

	init(draft: FeedbackDraft) { self.draft = draft }

	/// True once the tester has added something — text, audio, or markup. A bare, untouched
	/// screenshot doesn't count: there's nothing worth exporting yet.
	var hasContent: Bool {
		!comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || dictation.audioURL != nil || hasMarkup
	}

	private var hasMarkup: Bool {
		if store.hasAnnotations || store.isCropped { return true }
		#if canImport(UIKit)
		return !canvas.drawing.bounds.isEmpty
		#else
		return false
		#endif
	}

	/// The report to fold into a bulk export — only when the tester has added something.
	func reportForExport() -> FeedbackReport? { hasContent ? buildReport() : nil }

	/// Flatten the current edits into a sendable report. `nil` only if image encoding fails.
	func buildReport() -> FeedbackReport? {
		let annotated = includeScreenshot
			? MarkupFlattener.flatten(base: draft.originalImage, strokeImage: strokeImage, annotations: store.annotations, displaySize: displaySize, cropRect: store.cropRect)
			: nil
		return ReportBuilder.makeReport(draft: draft, comment: comment, category: category, annotated: annotated, audioData: dictation.audioData())
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
