//
//  MultiFingerGesture.swift
//  FeedbackKit
//
//  Installs a multi-finger long-press recognizer on the host window so it observes
//  touches without blocking the app's own gestures or content.
//

#if canImport(UIKit) && !os(watchOS)
import SwiftUI
import UIKit

struct MultiFingerLongPress: UIViewRepresentable {
	var touches = 2
	let action: () -> Void

	func makeUIView(context: Context) -> WindowGestureView {
		let recognizer = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.fired(_:)))
		recognizer.numberOfTouchesRequired = touches
		recognizer.minimumPressDuration = 0.4
		recognizer.cancelsTouchesInView = false
		recognizer.delegate = context.coordinator
		let view = WindowGestureView()
		view.recognizer = recognizer
		view.isUserInteractionEnabled = false
		return view
	}

	func updateUIView(_ uiView: WindowGestureView, context: Context) { context.coordinator.action = action }
	func makeCoordinator() -> Coordinator { Coordinator(action: action) }

	final class Coordinator: NSObject, UIGestureRecognizerDelegate {
		var action: () -> Void
		init(action: @escaping () -> Void) { self.action = action }
		@objc func fired(_ recognizer: UILongPressGestureRecognizer) {
			if recognizer.state == .began { action() }
		}
		func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
	}
}

final class WindowGestureView: UIView {
	var recognizer: UIGestureRecognizer?

	override func didMoveToWindow() {
		super.didMoveToWindow()
		guard let window, let recognizer, recognizer.view !== window else { return }
		window.addGestureRecognizer(recognizer)
	}
}
#endif
