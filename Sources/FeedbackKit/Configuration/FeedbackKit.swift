//
//  FeedbackKit.swift
//  FeedbackKit
//
//  Public entry point. Configure once at launch; trigger programmatically anywhere.
//

import Foundation
import SwiftUI

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

	// MARK: - Local collection route

	/// A ready-made screen listing locally-collected feedback (via `LocalCollectionTransport`)
	/// with delete + share-as-zip. Present it from a debug menu.
	@MainActor public static func collectionScreen() -> some View {
		FeedbackCollectionScreen()
	}

	/// Zip the whole local collection to a temp file and return its URL for custom sharing
	/// (e.g. a `ShareLink` or mail composer). `nil` if there is nothing to export.
	public static func exportCollection() async -> URL? {
		await Task.detached(priority: .userInitiated) {
			guard let store = try? FeedbackCollectionStore(), !store.isEmpty else { return nil }
			return try? store.zipArchive()
		}.value
	}
}
