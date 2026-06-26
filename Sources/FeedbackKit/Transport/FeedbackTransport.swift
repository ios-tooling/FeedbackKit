//
//  FeedbackTransport.swift
//  FeedbackKit
//
//  A destination a finished report can be delivered to. Conformers are the only
//  backend-specific code in the framework; everything else is transport-agnostic.
//

import Foundation

public protocol FeedbackTransport: Sendable {
	/// A short identifier used in logs and error reporting (e.g. "slack", "cloudkit").
	var name: String { get }

	/// Deliver the report. Throw on failure so the outbox can retry later.
	func send(_ report: FeedbackReport) async throws
}

public extension FeedbackTransport {
	var name: String { "\(type(of: self))" }
}
