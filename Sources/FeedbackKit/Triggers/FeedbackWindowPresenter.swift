//
//  FeedbackWindowPresenter.swift
//  FeedbackKit
//
//  Presents the editor in its own UIWindow so it appears above anything already
//  on screen — including sheets/fullScreenCovers the app may have presented, which
//  a root `.fullScreenCover` cannot cover.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit
import SwiftUI

@MainActor final class FeedbackWindowPresenter {
	private var window: UIWindow?
	private var flashWindow: UIWindow?

	/// A persistent, non-interactive window that hosts the capture flash so it shows
	/// above app content and sheets — consistent with the editor window. Idempotent.
	func installFlash(state: CaptureFlashState) {
		guard flashWindow == nil, let scene = activeWindowScene else { return }
		let host = UIHostingController(rootView: CaptureFlashView(state: state))
		host.view.backgroundColor = .clear

		let window = UIWindow(windowScene: scene)
		window.rootViewController = host
		window.windowLevel = .alert - 1   // above app/sheets, below the editor window
		window.isUserInteractionEnabled = false
		window.isHidden = false
		flashWindow = window
	}

	func present(_ draft: FeedbackDraft) {
		guard window == nil, let scene = activeWindowScene else { return }
		let host = UIHostingController(rootView: FeedbackEditorScreen(draft: draft))
		host.view.backgroundColor = .systemBackground

		let window = UIWindow(windowScene: scene)
		window.rootViewController = host
		window.windowLevel = .alert
		window.makeKeyAndVisible()
		self.window = window
	}

	func dismiss() {
		window?.isHidden = true
		window?.rootViewController = nil
		window = nil
	}

	private var activeWindowScene: UIWindowScene? {
		let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
		return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
	}
}
#endif
