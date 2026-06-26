//
//  FeedbackKitModifier.swift
//  FeedbackKit
//
//  `.feedbackKit(triggers:)` — installs the enabled triggers, the capture flash, and the
//  editor presentation. Apply once near the root of your app.
//

import SwiftUI

public extension View {
	func feedbackKit(triggers: FeedbackTriggers = .default) -> some View {
		modifier(FeedbackKitModifier(triggers: triggers))
	}
}

#if canImport(UIKit) && !os(watchOS)
struct FeedbackKitModifier: ViewModifier {
	let triggers: FeedbackTriggers
	@State private var controller = FeedbackController.shared

	func body(content: Content) -> some View {
		content
			.overlay { gestureOverlay }
			.overlay { if triggers.contains(.floatingButton) { FloatingTriggerButton() } }
			.overlay { CaptureFlashView(state: controller.flash) }
			.task { await observeShakes() }
			.fullScreenCover(item: draftBinding) { draft in
				FeedbackEditorScreen(draft: draft)
			}
	}

	@ViewBuilder private var gestureOverlay: some View {
		if triggers.contains(.multiFingerGesture) {
			MultiFingerLongPress(action: controller.trigger).allowsHitTesting(false)
		}
	}

	private var draftBinding: Binding<FeedbackDraft?> {
		Binding(get: { controller.activeDraft }, set: { if $0 == nil { controller.cancel() } })
	}

	private func observeShakes() async {
		guard triggers.contains(.shake) else { return }
		for await _ in NotificationCenter.default.notifications(named: .feedbackKitDidShake) {
			controller.trigger()
		}
	}
}
#else
struct FeedbackKitModifier: ViewModifier {
	let triggers: FeedbackTriggers
	func body(content: Content) -> some View { content }
}
#endif
