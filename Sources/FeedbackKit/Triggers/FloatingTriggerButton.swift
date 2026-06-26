//
//  FloatingTriggerButton.swift
//  FeedbackKit
//
//  A draggable bubble that invokes the feedback flow. Hides itself during capture so it
//  never appears in the screenshot.
//

#if canImport(UIKit) && !os(watchOS)
import SwiftUI

struct FloatingTriggerButton: View {
	@State private var controller = FeedbackController.shared
	@State private var offset = CGSize.zero

	var body: some View {
		Button(action: controller.trigger) {
			Image(systemName: "exclamationmark.bubble.fill")
				.font(.title2)
				.foregroundStyle(.white)
				.padding(14)
				.background(.tint, in: Circle())
				.shadow(radius: 4)
		}
		.offset(offset)
		.gesture(
			DragGesture()
				.onChanged { offset = $0.translation }
				.onEnded { offset = $0.translation }
		)
		.opacity(controller.isCapturing ? 0 : 1)
		.padding()
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
		.allowsHitTesting(!controller.isCapturing)
	}
}
#endif
