//
//  FeedbackPagerScreen.swift
//  FeedbackKit
//
//  The presented feedback experience: the editor for the current capture on the first page,
//  swipe left (iOS) — or the second tab (macOS) — for the accumulated-feedback export screen.
//

import SwiftUI

struct FeedbackPagerScreen: View {
	let draft: FeedbackDraft
	@State private var selection = 0

	var body: some View {
		TabView(selection: $selection) {
			FeedbackEditorScreen(draft: draft)
				.tag(0)
				.tabItem { Label("Report", systemImage: "square.and.pencil") }
			FeedbackCollectionScreen()
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
