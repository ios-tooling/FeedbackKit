//
//  FeedbackPagerScreen.swift
//  FeedbackKit
//
//  The presented feedback experience: the editor for the current capture on the first page,
//  swipe left (iOS) — or the second tab (macOS) — for the accumulated-feedback export screen.
//

import SwiftUI

struct FeedbackPagerScreen: View {
	@State private var editing: FeedbackDraftEditing
	@State private var selection = 0

	init(draft: FeedbackDraft) {
		_editing = State(initialValue: FeedbackDraftEditing(draft: draft))
	}

	var body: some View {
		TabView(selection: $selection) {
			FeedbackEditorScreen(editing: editing)
				.tag(0)
				.tabItem { Label("Report", systemImage: "square.and.pencil") }
			FeedbackCollectionScreen(currentDraft: editing)
				.tag(1)
				.tabItem { Label("Export", systemImage: "tray.full") }
		}
		#if canImport(UIKit)
		.tabViewStyle(.page(indexDisplayMode: .always))
		.indexViewStyle(.page(backgroundDisplayMode: .always))
		#endif
		.preferredColorScheme(.dark)
	}
}
