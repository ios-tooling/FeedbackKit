//
//  MarkupModel.swift
//  FeedbackKit
//
//  Tools and the structured-annotation model. Annotation geometry is stored in
//  normalized [0,1] image coordinates so it survives any display size.
//

import SwiftUI

enum MarkupTool: String, CaseIterable, Identifiable {
	case draw, arrow, box, text, blur, crop
	var id: String { rawValue }

	var symbolName: String {
		switch self {
		case .draw: "pencil.tip"
		case .arrow: "arrow.up.right"
		case .box: "rectangle"
		case .text: "textformat"
		case .blur: "drop.halffull"
		case .crop: "crop"
		}
	}

	/// Freehand drawing is handled by PencilKit; the rest are placed overlay objects.
	var isFreehand: Bool { self == .draw }
}

struct Annotation: Identifiable {
	enum Kind { case arrow, box, text, blur }
	let id = UUID()
	var kind: Kind
	var start: CGPoint          // normalized 0...1
	var end: CGPoint            // normalized 0...1
	var color: Color
	var text: String = ""

	func rect(in size: CGSize) -> CGRect {
		let a = CGPoint(x: start.x * size.width, y: start.y * size.height)
		let b = CGPoint(x: end.x * size.width, y: end.y * size.height)
		return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
	}
}

/// A freehand stroke in normalized [0,1] image coordinates. Used by the macOS canvas
/// (iOS freehand lives in PencilKit's `PKDrawing` instead).
struct Stroke: Identifiable {
	let id = UUID()
	var points: [CGPoint]       // normalized 0...1
	var color: Color
	var width: CGFloat = 4      // line width in display points (rasterized, then scaled on flatten)
}

@MainActor @Observable final class MarkupStore {
	nonisolated static let fullCrop = CGRect(x: 0, y: 0, width: 1, height: 1)

	/// `nil` = no active tool (palette hidden, canvas inert). Tapping the selected
	/// tool again deselects it.
	var tool: MarkupTool? = .draw
	var color: Color = .red
	var annotations: [Annotation] = []
	/// Freehand strokes (macOS). Empty/unused on iOS, where PencilKit owns freehand.
	var strokes: [Stroke] = []
	/// Crop rectangle in normalized [0,1] image coordinates; full image by default.
	var cropRect = MarkupStore.fullCrop

	var isFreehand: Bool { tool == .draw }
	var placesAnnotations: Bool {
		switch tool {
		case .arrow, .box, .text, .blur: true
		default: false
		}
	}

	func add(_ annotation: Annotation) { annotations.append(annotation) }
	func add(_ stroke: Stroke) { strokes.append(stroke) }
	/// Undo the most recent markup (freehand stroke or structured annotation, newest first).
	func undoLastAnnotation() {
		if !strokes.isEmpty { strokes.removeLast() }
		else if !annotations.isEmpty { annotations.removeLast() }
	}
	var hasAnnotations: Bool { !annotations.isEmpty || !strokes.isEmpty }

	var isCropped: Bool { cropRect != MarkupStore.fullCrop }
	func resetCrop() { cropRect = MarkupStore.fullCrop }
}
