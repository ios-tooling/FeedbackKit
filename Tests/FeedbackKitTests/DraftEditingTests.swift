//
//  DraftEditingTests.swift
//  FeedbackKitTests
//
//  The in-progress draft is only foldable into an export once something has been added.
//

import Testing
import Foundation
@testable import FeedbackKit
#if canImport(AppKit)
import AppKit
#endif

@MainActor
struct DraftEditingTests {
	#if canImport(AppKit)
	private func makeEditing() -> FeedbackDraftEditing {
		let draft = FeedbackDraft(
			originalImage: NSImage(size: NSSize(width: 1, height: 1)),
			context: .empty,
			metadata: makeSampleReport().metadata,
			userID: nil,
			breadcrumbs: nil
		)
		let editing = FeedbackDraftEditing(draft: draft)
		editing.includeScreenshot = false   // text-only, so no image flattening is needed
		return editing
	}

	@Test func emptyDraftIsNotExported() {
		#expect(makeEditing().hasContent == false)
		#expect(makeEditing().reportForExport() == nil)
	}

	@Test func draftWithCommentIsExported() {
		let editing = makeEditing()
		editing.comment = "found a bug"
		#expect(editing.hasContent)
		#expect(editing.reportForExport()?.comment == "found a bug")
	}
	#endif
}
