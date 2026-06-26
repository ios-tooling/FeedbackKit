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
		context.coordinator.updatePicker(active: isActive, canvas: canvas)
	}

	func makeCoordinator() -> Coordinator { Coordinator() }

	@MainActor final class Coordinator {
		let toolPicker = PKToolPicker()

		// The editor is presented in its own window, so on the first layout pass the
		// canvas may not be attached to a window yet. Retry briefly until it is, then
		// show the tool picker — otherwise it never appears (and only the default pen works).
		func updatePicker(active: Bool, canvas: PKCanvasView, attempt: Int = 0) {
			Task { @MainActor in
				guard canvas.window != nil else {
					guard attempt < 12 else { return }
					try? await Task.sleep(nanoseconds: 50_000_000)
					updatePicker(active: active, canvas: canvas, attempt: attempt + 1)
					return
				}
				toolPicker.setVisible(active, forFirstResponder: canvas)
				if active {
					toolPicker.addObserver(canvas)
					canvas.becomeFirstResponder()
				} else {
					canvas.resignFirstResponder()
				}
			}
		}
	}
}
#endif
