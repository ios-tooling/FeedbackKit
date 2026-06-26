//
//  PencilCanvasRepresentable.swift
//  FeedbackKit
//
//  Hosts a PKCanvasView for freehand strokes and shows the native tool picker
//  (pen / highlighter / eraser / colors / undo-redo) when the draw tool is active.
//

#if canImport(UIKit) && !os(watchOS)
import SwiftUI
import PencilKit

struct PencilCanvasRepresentable: UIViewRepresentable {
	let canvas: PKCanvasView
	let isActive: Bool

	func makeUIView(context: Context) -> PKCanvasView {
		canvas.drawingPolicy = .anyInput
		canvas.backgroundColor = .clear
		canvas.isOpaque = false
		// PKCanvasView is a scroll view; the tool picker would otherwise adjust its
		// contentInset/offset and shift strokes away from where they were drawn when
		// flattened. Pin the drawing coordinate space to the view's frame.
		canvas.isScrollEnabled = false
		canvas.contentInsetAdjustmentBehavior = .never
		canvas.contentInset = .zero
		return canvas
	}

	func updateUIView(_ canvas: PKCanvasView, context: Context) {
		canvas.isUserInteractionEnabled = isActive
		let picker = context.coordinator.toolPicker
		Task { @MainActor in
			guard canvas.window != nil else { return }
			picker.setVisible(isActive, forFirstResponder: canvas)
			if isActive {
				picker.addObserver(canvas)
				canvas.becomeFirstResponder()
			} else {
				canvas.resignFirstResponder()
			}
		}
	}

	func makeCoordinator() -> Coordinator { Coordinator() }

	final class Coordinator {
		let toolPicker = PKToolPicker()
	}
}
#endif
