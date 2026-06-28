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

#elseif canImport(AppKit)
import AppKit
import SwiftUI

@MainActor final class FeedbackWindowPresenter {
	private var window: NSWindow?
	private var closeDelegate: EditorWindowDelegate?

	/// No-op on macOS — the white capture flash is iOS theatrics.
	func installFlash(state: CaptureFlashState) {}

	func present(_ draft: FeedbackDraft) {
		guard window == nil else { return }
		let host = NSHostingController(rootView: FeedbackEditorScreen(draft: draft))
		let window = NSWindow(contentViewController: host)
		window.title = "Feedback"
		window.styleMask = [.titled, .closable, .fullSizeContentView]
		window.isReleasedWhenClosed = false
		window.setContentSize(defaultSize)
		window.center()

		let delegate = EditorWindowDelegate { [weak self] in self?.handleUserClose() }
		window.delegate = delegate
		closeDelegate = delegate

		window.makeKeyAndOrderFront(nil)
		NSApp.activate(ignoringOtherApps: true)
		self.window = window
	}

	func dismiss() {
		window?.delegate = nil      // suppress the delegate so close isn't read as a cancel
		window?.close()
		window = nil
		closeDelegate = nil
	}

	/// The user clicked the window's close button — treat it as Cancel.
	private func handleUserClose() {
		window = nil
		closeDelegate = nil
		FeedbackController.shared.cancel()
	}

	private var defaultSize: CGSize {
		guard let visible = NSScreen.main?.visibleFrame.size else { return CGSize(width: 1024, height: 720) }
		return CGSize(width: visible.width * 0.6, height: visible.height * 0.7)
	}
}

private final class EditorWindowDelegate: NSObject, NSWindowDelegate {
	let onClose: () -> Void
	init(onClose: @escaping () -> Void) { self.onClose = onClose }
	func windowWillClose(_ notification: Notification) { onClose() }
}
#endif
