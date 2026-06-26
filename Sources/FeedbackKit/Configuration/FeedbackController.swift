//
//  FeedbackController.swift
//  FeedbackKit
//
//  The runtime brain: holds config + outbox, captures the screen on trigger, owns the
//  editor presentation, and submits finished reports. Observed by the root modifier.
//

import SwiftUI
import Chronicle

@MainActor @Observable public final class FeedbackController {
	public static let shared = FeedbackController()

	public let flash = CaptureFlashState()
	/// The most recently presented screen's context, used by triggers fired from outside
	/// the view tree (shake / gesture / programmatic). The `.feedbackContext` modifier keeps
	/// this current; the deepest/last-appeared screen wins.
	public var currentContext: FeedbackContext = .empty
	public private(set) var activeDraft: FeedbackDraft?
	/// True while grabbing pixels — FeedbackKit chrome hides itself so it isn't captured.
	public private(set) var isCapturing = false

	private var configuration: FeedbackKitConfiguration?
	private var outbox: FeedbackOutbox?

	public var isConfigured: Bool { configuration != nil }
	public var isPresenting: Bool { activeDraft != nil }
	public var pendingCount: Int { outbox?.pendingCount ?? 0 }

	private init() {}

	func configure(_ config: FeedbackKitConfiguration) {
		configuration = config
		outbox = try? FeedbackOutbox(transport: config.transport)
		Task { await outbox?.drain() }   // flush anything left from a previous launch
	}

	func trigger() { trigger(context: currentContext) }

	func trigger(context: FeedbackContext) {
		guard !isPresenting, configuration != nil else { return }
		Task { await performTrigger(context: context) }
	}

	private func performTrigger(context: FeedbackContext) async {
		guard let configuration else { return }
		isCapturing = true
		// Let SwiftUI hide FeedbackKit chrome (e.g. the floating button) before the grab.
		try? await Task.sleep(nanoseconds: 60_000_000)

		guard let image = ScreenCapturer.captureActiveScene() else {
			isCapturing = false
			// No capture on this platform (macOS is deferred) or capture failed — log, don't fail silently.
			Chronicle.track("feedbackkit_capture_unavailable")
			return
		}
		isCapturing = false
		flash.flash()

		let breadcrumbs = await ChronicleBreadcrumbs.collect(limit: configuration.breadcrumbLimit)
		activeDraft = FeedbackDraft(
			originalImage: image,
			context: context,
			metadata: FeedbackMetadata.current(),
			userID: configuration.userID(),
			breadcrumbs: breadcrumbs
		)
	}

	func submit(_ report: FeedbackReport) {
		outbox?.submit(report)
		activeDraft = nil
	}

	func cancel() {
		activeDraft = nil
	}
}
