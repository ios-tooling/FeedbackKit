//
//  CollectionRow.swift
//  FeedbackKit
//
//  A single collected-feedback row: thumbnail, comment, category, date, and an audio marker.
//

import SwiftUI

struct CollectionRow: View {
	let item: CollectionItem

	var body: some View {
		HStack(spacing: 12) {
			thumbnail
			VStack(alignment: .leading, spacing: 2) {
				Text(item.comment.isEmpty ? "No comment" : item.comment)
					.lineLimit(2)
					.foregroundStyle(item.comment.isEmpty ? .secondary : .primary)
				HStack(spacing: 6) {
					Label(item.category.displayName, systemImage: item.category.symbolName)
					if item.audioURL != nil { Image(systemName: "waveform") }
					Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
				}
				.font(.caption)
				.foregroundStyle(.secondary)
			}
			Spacer(minLength: 8)
			ShareLink(item: SharedReport(item: item),
					  preview: SharePreview(item.comment.isEmpty ? "Feedback" : item.comment)) {
				Image(systemName: "square.and.arrow.up")
			}
			.buttonStyle(.borderless)
			.labelStyle(.iconOnly)
		}
	}

	@ViewBuilder private var thumbnail: some View {
		if let url = item.screenshotURL {
			AsyncImage(url: url) { image in
				image.resizable().scaledToFill()
			} placeholder: {
				Color.secondary.opacity(0.15)
			}
			.frame(width: 44, height: 44)
			.clipShape(RoundedRectangle(cornerRadius: 6))
		} else {
			RoundedRectangle(cornerRadius: 6)
				.fill(Color.secondary.opacity(0.15))
				.frame(width: 44, height: 44)
				.overlay { Image(systemName: item.category.symbolName).foregroundStyle(.secondary) }
		}
	}
}
