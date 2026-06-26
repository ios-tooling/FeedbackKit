//
//  FeedbackKit.swift
//  FeedbackKit
//
//  Public entry point. Configure once at launch; trigger programmatically anywhere.
//

import Foundation

public enum FeedbackKit {
	/// Configure with a single transport (often a `MultiTransport`).
	@MainActor public static func configure(transport: FeedbackTransport, userID: @escaping @Sendable () -> String? = { nil }) {
		FeedbackController.shared.configure(FeedbackKitConfiguration(transport: transport, userID: userID))
	}

	/// Configure with several transports, fanned out.
	@MainActor public static func configure(transports: [FeedbackTransport], userID: @escaping @Sendable () -> String? = { nil }) {
		FeedbackController.shared.configure(FeedbackKitConfiguration(transports: transports, userID: userID))
	}

	/// Configure with a fully-formed configuration.
	@MainActor public static func configure(_ configuration: FeedbackKitConfiguration) {
		FeedbackController.shared.configure(configuration)
	}

	/// Invoke the feedback flow programmatically (e.g. from a debug-menu row).
	@MainActor public static func trigger() {
		FeedbackController.shared.trigger()
	}

	@MainActor public static var pendingCount: Int { FeedbackController.shared.pendingCount }
}
