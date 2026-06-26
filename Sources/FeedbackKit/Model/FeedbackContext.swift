//
//  FeedbackContext.swift
//  FeedbackKit
//

import Foundation

/// Host-supplied "where am I" information, resolved at capture time from the environment.
public struct FeedbackContext: Codable, Sendable, Equatable {
	/// A human-readable name for the current screen, e.g. "CartScreen".
	public var screenName: String?
	/// Arbitrary host-injected key/value pairs, e.g. ["cartID": "1234"].
	public var metadata: [String: String]

	public init(screenName: String? = nil, metadata: [String: String] = [:]) {
		self.screenName = screenName
		self.metadata = metadata
	}

	public static let empty = FeedbackContext()
}
