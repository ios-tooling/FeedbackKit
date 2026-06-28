//
//  FeedbackEditorToolbar.swift
//  FeedbackKit
//
//  The editor's navigation toolbar, factored out so the screen stays small. Placements
//  differ per platform: iOS uses bar-trailing items, macOS uses the primary-action area.
//

import SwiftUI

struct FeedbackEditorToolbar: ToolbarContent {
	@Binding var category: FeedbackCategory
	@Binding var includeScreenshot: Bool
	@Binding var commentExpanded: Bool
	let canSend: Bool
	let onCancel: () -> Void
	let onSend: () -> Void

	var body: some ToolbarContent {
		ToolbarItem(placement: .cancellationAction) {
			Button("Cancel", role: .cancel, action: onCancel)
		}
		ToolbarItem(placement: .principal) {
			Picker("Category", selection: $category) {
				ForEach(FeedbackCategory.allCases, id: \.self) { category in
					Label(category.displayName, systemImage: category.symbolName).tag(category)
				}
			}
			.pickerStyle(.menu)
		}
		ToolbarItem(placement: Self.trailing) {
			Button(includeScreenshot ? "Hide screenshot" : "Add screenshot", systemImage: includeScreenshot ? "photo" : "photo.badge.plus") {
				withAnimation { includeScreenshot.toggle() }
			}
		}
		if includeScreenshot {
			ToolbarItem(placement: Self.trailing) {
				Button("Comment", systemImage: commentExpanded ? "text.bubble.fill" : "text.bubble") {
					withAnimation { commentExpanded.toggle() }
				}
			}
		}
		ToolbarItem(placement: .confirmationAction) {
			Button("Send", action: onSend).disabled(!canSend)
		}
	}

	private static var trailing: ToolbarItemPlacement {
		#if canImport(UIKit)
		.topBarTrailing
		#else
		.primaryAction
		#endif
	}
}
