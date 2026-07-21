//
//  CollectionScreenModel.swift
//  FeedbackKit
//
//  Backing state for FeedbackCollectionScreen: loads the bundles and keeps a ready-to-share
//  zip of the whole collection in step with edits.
//

import SwiftUI

@MainActor @Observable final class CollectionScreenModel {
	private(set) var items: [CollectionItem] = []
	private(set) var zipURL: URL?

	private let store: FeedbackCollectionStore?

	init() { store = try? FeedbackCollectionStore() }

	func reload() {
		items = store?.items() ?? []
		Task { await refreshZip() }
	}

	func delete(at offsets: IndexSet) {
		for index in offsets { try? store?.remove(items[index].id) }
		reload()
	}

	func clearAll() {
		try? store?.removeAll()
		reload()
	}

	private func refreshZip() async {
		guard let store, !items.isEmpty else { zipURL = nil; return }
		zipURL = await Task.detached(priority: .userInitiated) { try? store.zipArchive() }.value
	}
}
