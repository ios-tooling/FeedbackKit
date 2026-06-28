//
//  ScreenCapturer.swift
//  FeedbackKit
//
//  Grabs the current screen as an image. Composites every window in the active scene
//  (app content, presented sheets/alerts, keyboard) for the fullest faithful capture.
//  Uses drawHierarchy under the hood via CrossPlatformKit's UIView.extractImage.
//

import Foundation
import CrossPlatformKit

#if canImport(UIKit) && !os(watchOS)
import UIKit
import Suite

@MainActor public enum ScreenCapturer {
	/// Capture the active scene. Call *before* presenting any FeedbackKit UI, and after
	/// hiding FeedbackKit's own chrome, so neither ends up in the image.
	public static func captureActiveScene() -> UXImage? {
		guard let scene = activeScene() else { return nil }
		let windows = scene.windows
			.filter { !$0.isHidden && $0.alpha > 0.01 && $0.bounds.size != .zero }
			.sorted { $0.windowLevel < $1.windowLevel }
		guard let size = (scene.frontWindow ?? windows.first)?.bounds.size, size != .zero else { return nil }

		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image { _ in
			for window in windows {
				window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
			}
		}
	}

	private static func activeScene() -> UIWindowScene? {
		let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
		return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
	}
}

#elseif canImport(AppKit)

import AppKit

@MainActor public enum ScreenCapturer {
	/// Snapshot the app's key window content (no Screen Recording permission needed). Scopes
	/// the grab to our own app, matching the iOS behaviour. Call before presenting the editor.
	public static func captureActiveScene() -> UXImage? {
		let window = NSApp.keyWindow ?? NSApp.windows.first { $0.isVisible && $0.contentView != nil }
		return window?.contentView?.extractImage()
	}
}

#else

@MainActor public enum ScreenCapturer {
	/// Screen capture is unavailable on this platform; returns nil.
	public static func captureActiveScene() -> UXImage? { nil }
}

#endif
