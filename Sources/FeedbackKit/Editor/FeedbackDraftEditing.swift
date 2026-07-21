//
//  FeedbackDraftEditing.swift
//  FeedbackKit
//
//  Live state for the report being edited, shared between the editor page and the export
//  page so the in-progress report can appear as a "Draft — unsent" row while you type.
//

import Foundation

@MainActor @Observable final class FeedbackDraftEditing {
	let draft: FeedbackDraft
	var comment = ""
	var category: FeedbackCategory = .bug

	init(draft: FeedbackDraft) { self.draft = draft }
}
