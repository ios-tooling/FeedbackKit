//
//  DraftRow.swift
//  FeedbackKit
//
//  The in-progress report shown at the top of the export screen, reflecting the editor's
//  live comment and category until it is sent and becomes a saved collection item.
//

import SwiftUI
import CrossPlatformKit

struct DraftRow: View {
	let editing: FeedbackDraftEditing

	var body: some View {
		HStack(spacing: 12) {
			Image(uxImage: editing.draft.originalImage)
				.resizable()
				.scaledToFill()
				.frame(width: 44, height: 44)
				.clipShape(RoundedRectangle(cornerRadius: 6))

			VStack(alignment: .leading, spacing: 2) {
				Text(editing.comment.isEmpty ? "No comment yet" : editing.comment)
					.lineLimit(2)
					.foregroundStyle(editing.comment.isEmpty ? .secondary : .primary)
				HStack(spacing: 6) {
					Label(editing.category.displayName, systemImage: editing.category.symbolName)
					Text("Unsent")
						.padding(.horizontal, 6)
						.padding(.vertical, 1)
						.background(.tint.opacity(0.2), in: Capsule())
				}
				.font(.caption)
				.foregroundStyle(.secondary)
			}
		}
	}
}
