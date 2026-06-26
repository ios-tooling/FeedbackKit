//
//  CaptureFlash.swift
//  FeedbackKit
//
//  The white "screenshot" flash — visual only, no shutter sound, no thumbnail.
//

import SwiftUI

@MainActor @Observable public final class CaptureFlashState {
	public private(set) var opacity: Double = 0
	public init() {}

	/// Snap to white, then fade out — mimics the native screenshot flash.
	public func flash() {
		opacity = 1
		withAnimation(.easeOut(duration: 0.35)) { opacity = 0 }
	}
}

struct CaptureFlashView: View {
	let state: CaptureFlashState

	var body: some View {
		Color.white
			.opacity(state.opacity)
			.ignoresSafeArea()
			.allowsHitTesting(false)
	}
}
