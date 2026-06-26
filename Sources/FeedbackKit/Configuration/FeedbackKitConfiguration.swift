//
//  FeedbackKitConfiguration.swift
//  FeedbackKit
//
//  App-wide, set-once configuration: where reports go and who is reporting.
//

import Foundation

public struct FeedbackKitConfiguration: Sendable {
	public let transport: FeedbackTransport
	/// Re-read at each capture so it always reflects the current session.
	public let userID: @Sendable () -> String?
	/// How many recent Chronicle breadcrumbs to attach (0 disables).
	public let breadcrumbLimit: Int

	public init(
		transport: FeedbackTransport,
		userID: @escaping @Sendable () -> String? = { nil },
		breadcrumbLimit: Int = 50
	) {
		self.transport = transport
		self.userID = userID
		self.breadcrumbLimit = breadcrumbLimit
	}

	/// Convenience for fanning out to several destinations.
	public init(
		transports: [FeedbackTransport],
		userID: @escaping @Sendable () -> String? = { nil },
		breadcrumbLimit: Int = 50
	) {
		self.init(transport: MultiTransport(transports), userID: userID, breadcrumbLimit: breadcrumbLimit)
	}
}
