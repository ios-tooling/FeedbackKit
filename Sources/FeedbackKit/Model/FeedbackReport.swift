//
//  FeedbackReport.swift
//  FeedbackKit
//
//  The self-contained, Codable payload handed to every transport. Images travel
//  as JPEG `Data` so the report serializes to a single file in the outbox.
//

import Foundation

public struct FeedbackReport: Codable, Sendable, Identifiable, Equatable {
	public let id: UUID
	public let createdAt: Date
	public var comment: String
	public var category: FeedbackCategory
	public var metadata: FeedbackMetadata
	public var context: FeedbackContext
	public var userID: String?
	public var breadcrumbs: [BreadcrumbSummary]?

	/// Flattened capture (base screenshot + annotations), JPEG-encoded.
	public var annotatedImageData: Data
	/// The clean, unannotated capture, JPEG-encoded. Occasionally useful for review.
	public var originalImageData: Data?

	public init(
		id: UUID,
		createdAt: Date,
		comment: String,
		category: FeedbackCategory,
		metadata: FeedbackMetadata,
		context: FeedbackContext = .empty,
		userID: String? = nil,
		breadcrumbs: [BreadcrumbSummary]? = nil,
		annotatedImageData: Data,
		originalImageData: Data? = nil
	) {
		self.id = id
		self.createdAt = createdAt
		self.comment = comment
		self.category = category
		self.metadata = metadata
		self.context = context
		self.userID = userID
		self.breadcrumbs = breadcrumbs
		self.annotatedImageData = annotatedImageData
		self.originalImageData = originalImageData
	}
}
