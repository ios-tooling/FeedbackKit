//
//  FeedbackDraft.swift
//  FeedbackKit
//
//  In-flight feedback being annotated by the user, before it becomes a FeedbackReport.
//

import Foundation
import CrossPlatformKit

@MainActor public struct FeedbackDraft: Identifiable {
	public let id = UUID()
	public let originalImage: UXImage
	public let context: FeedbackContext
	public let metadata: FeedbackMetadata
	public let userID: String?
	public let breadcrumbs: [BreadcrumbSummary]?
}
