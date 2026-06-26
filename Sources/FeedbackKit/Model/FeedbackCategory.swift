//
//  FeedbackCategory.swift
//  FeedbackKit
//

import Foundation

/// How the tester classifies a report. Kept deliberately small for v1 (no severity).
public enum FeedbackCategory: String, Codable, CaseIterable, Sendable {
	case bug
	case idea
	case other

	public var displayName: String {
		switch self {
		case .bug: "Bug"
		case .idea: "Idea"
		case .other: "Other"
		}
	}

	public var symbolName: String {
		switch self {
		case .bug: "ladybug"
		case .idea: "lightbulb"
		case .other: "ellipsis.bubble"
		}
	}
}
