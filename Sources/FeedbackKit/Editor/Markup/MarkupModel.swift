//
//  MarkupModel.swift
//  FeedbackKit
//
//  Tools and the structured-annotation model. Annotation geometry is stored in
//  normalized [0,1] image coordinates so it survives any display size.
//

#if canImport(UIKit) && !os(watchOS)
import SwiftUI

enum MarkupTool: String, CaseIterable, Identifiable {
	case draw, arrow, box, text, blur
	var id: String { rawValue }

	var symbolName: String {
		switch self {
		case .draw: "pencil.tip"
		case .arrow: "arrow.up.right"
		case .box: "rectangle"
		case .text: "textformat"
		case .blur: "drop.halffull"
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

@MainActor @Observable final class MarkupStore {
	var tool: MarkupTool = .draw
	var color: Color = .red
	var annotations: [Annotation] = []

	func add(_ annotation: Annotation) { annotations.append(annotation) }
	func undoLastAnnotation() { if !annotations.isEmpty { annotations.removeLast() } }
	var hasAnnotations: Bool { !annotations.isEmpty }
}
#endif
