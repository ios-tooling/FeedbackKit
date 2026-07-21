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
				if let zipURL = model.zipURL {
					ShareLink(item: zipURL) { Label("Export", systemImage: "square.and.arrow.up") }
				}
			}
		}
		.task { model.reload() }
	}
}
