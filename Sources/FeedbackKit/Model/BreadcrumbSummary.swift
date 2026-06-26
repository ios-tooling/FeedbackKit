//
//  BreadcrumbSummary.swift
//  FeedbackKit
//
//  A Codable snapshot of a Chronicle event, so "what the user did right before"
//  travels with the report. Populated in the Chronicle integration step.
//

import Foundation

public struct BreadcrumbSummary: Codable, Sendable, Equatable {
	public var name: String
	public var timestamp: Date
	public var context: [String: String]?
	public var source: String?

	public init(name: String, timestamp: Date, context: [String: String]? = nil, source: String? = nil) {
		self.name = name
		self.timestamp = timestamp
		self.context = context
		self.source = source
	}
}
