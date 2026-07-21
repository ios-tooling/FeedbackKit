//
//  FeedbackCollectionScreen.swift
//  FeedbackKit
//
//  Public review screen for the local collection route: lists collected feedback, allows
//  deleting items, and shares the whole collection as a single zip. Present it from a
//  debug menu — it is self-contained in its own NavigationStack.
//

import SwiftUI

public struct FeedbackCollectionScreen: View {
	@State private var model = CollectionScreenModel()
	@State private var confirmingClear = false

	public init() {}

	public var body: some View {
		NavigationStack {
			Group {
				if model.items.isEmpty {
					ContentUnavailableView("No Feedback Yet", systemImage: "tray",
										   description: Text("Collected feedback will appear here, ready to export."))
				} else {
					List {
						ForEach(model.items) { CollectionRow(item: $0) }
							.onDelete(perform: model.delete)
					}
				}
			}
			.navigationTitle("Feedback")
			.toolbar {
				ToolbarItem(placement: Self.trailing) {
					if let zipURL = model.zipURL {
						ShareLink(item: zipURL) { Label("Export All", systemImage: "square.and.arrow.up") }
					}
				}
				ToolbarItem(placement: Self.trailing) {
					if !model.items.isEmpty {
						Button(role: .destructive) { confirmingClear = true } label: { Label("Clear All", systemImage: "trash") }
					}
				}
			}
			.alert("Clear all feedback?", isPresented: $confirmingClear) {
				Button("Clear All", role: .destructive) { model.clearAll() }
				Button("Cancel", role: .cancel) {}
			} message: {
				Text("This permanently deletes every collected report on this device.")
			}
		}
		.task { model.reload() }
	}

	private static var trailing: ToolbarItemPlacement {
		#if canImport(UIKit)
		.topBarTrailing
		#else
		.primaryAction
		#endif
	}
}
