//
//  ReportBuilder.swift
//  FeedbackKit
//
//  Turns an annotated draft into a sendable FeedbackReport (JPEG-encoding both images).
//

#if canImport(UIKit) && !os(watchOS)
import UIKit
import CrossPlatformKit

enum ReportBuilder {
	static let jpegQuality: CGFloat = 0.85

	/// Pass `annotated: nil` for a text-only report (the tester hid the screenshot).
	@MainActor static func makeReport(draft: FeedbackDraft, comment: String, category: FeedbackCategory, annotated: UXImage?) -> FeedbackReport? {
		let annotatedData = annotated?.jpegData(compressionQuality: jpegQuality)
		if annotated != nil, annotatedData == nil { return nil }
		return FeedbackReport(
			id: UUID(),
			createdAt: Date(),
			comment: comment,
			category: category,
			metadata: draft.metadata,
			context: draft.context,
			userID: draft.userID,
			breadcrumbs: draft.breadcrumbs,
			annotatedImageData: annotatedData,
			originalImageData: annotated == nil ? nil : draft.originalImage.jpegData(compressionQuality: jpegQuality)
		)
	}
}
#endif
