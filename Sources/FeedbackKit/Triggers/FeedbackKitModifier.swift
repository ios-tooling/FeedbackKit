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
	@State private var presenter = FeedbackWindowPresenter()

	func body(content: Content) -> some View {
		content
			.overlay { gestureOverlay }
			.overlay { if triggers.contains(.floatingButton) { FloatingTriggerButton() } }
			.task { await observeShakes() }
			// Both the flash and the editor live in their own windows so they show over
			// any sheet the app already has up (a root overlay/.fullScreenCover would be
			// blocked by it).
			.onAppear { presenter.installFlash(state: controller.flash) }
			.onChange(of: controller.isPresenting) { _, presenting in
				if presenting, let draft = controller.activeDraft { presenter.present(draft) }
				else { presenter.dismiss() }
			}
	}

	@ViewBuilder private var gestureOverlay: some View {
		if triggers.contains(.multiFingerGesture) {
			MultiFingerLongPress(action: controller.trigger).allowsHitTesting(false)
		}
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
