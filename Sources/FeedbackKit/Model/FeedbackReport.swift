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

	/// Flattened capture (base screenshot + annotations), JPEG-encoded. `nil` for a
	/// text-only report where the tester chose to omit the screenshot.
	public var annotatedImageData: Data?
	/// The clean, unannotated capture, JPEG-encoded. Occasionally useful for review.
	public var originalImageData: Data?
	/// The dictated audio the tester recorded, AAC/`.m4a`-encoded. `nil` when no audio
	/// was recorded. Materialized to disk by `LocalCollectionTransport`; remote transports
	/// convey the spoken content via the transcript in `comment` instead.
	public var audioData: Data?

	public init(
		id: UUID,
		createdAt: Date,
		comment: String,
		category: FeedbackCategory,
		metadata: FeedbackMetadata,
		context: FeedbackContext = .empty,
		userID: String? = nil,
		breadcrumbs: [BreadcrumbSummary]? = nil,
		annotatedImageData: Data? = nil,
		originalImageData: Data? = nil,
		audioData: Data? = nil
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
		self.audioData = audioData
	}
}
