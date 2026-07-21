//
//  ReportBuilder.swift
//  FeedbackKit
//
//  Turns an annotated draft into a sendable FeedbackReport (JPEG-encoding both images).
//

import Foundation
import CrossPlatformKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum ReportBuilder {
	static let jpegQuality: CGFloat = 0.85

	/// Pass `annotated: nil` for a text-only report (the tester hid the screenshot) and
	/// `audioData: nil` when no dictation was recorded.
	@MainActor static func makeReport(draft: FeedbackDraft, comment: String, category: FeedbackCategory, annotated: UXImage?, audioData: Data? = nil) -> FeedbackReport? {
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
			originalImageData: annotated == nil ? nil : draft.originalImage.jpegData(compressionQuality: jpegQuality),
			audioData: audioData
		)
	}
}
