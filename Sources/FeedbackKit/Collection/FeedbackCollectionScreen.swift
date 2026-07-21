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
	@State private var hasSharedThisSession = false
	private let currentDraft: FeedbackDraftEditing?

	public init() { currentDraft = nil }
	init(currentDraft: FeedbackDraftEditing?) { self.currentDraft = currentDraft }

	public var body: some View {
		NavigationStack {
			Group {
				if currentDraft == nil, model.items.isEmpty {
					ContentUnavailableView("No Feedback Yet", systemImage: "tray",
										   description: Text("Collected feedback will appear here, ready to export."))
				} else {
					List {
						if let currentDraft {
							Section("In Progress") { DraftRow(editing: currentDraft) }
						}
						if !model.items.isEmpty {
							Section("Collected") {
								ForEach(model.items) { CollectionRow(item: $0) }
									.onDelete(perform: model.delete)
							}
						}
					}
				}
			}
			.navigationTitle("Feedback")
			.toolbar {
				ToolbarItem(placement: Self.trailing) {
					if !model.items.isEmpty || currentDraft != nil {
						ShareLink(item: ExportBundle(currentDraft: currentDraft), preview: SharePreview(FeedbackCollectionStore.defaultArchiveName)) {
							Label("Export All", systemImage: "square.and.arrow.up")
						}
						.simultaneousGesture(TapGesture().onEnded { hasSharedThisSession = true })
					}
				}
			}
			.safeAreaInset(edge: .bottom) { clearButton }
			.alert("Clear all feedback?", isPresented: $confirmingClear) {
				Button("Clear All", role: .destructive) { model.clearAll() }
				Button("Cancel", role: .cancel) {}
			} message: {
				Text("This permanently deletes every collected report on this device.")
			}
		}
		.task { model.reload() }
	}

	@ViewBuilder private var clearButton: some View {
		if !model.items.isEmpty {
			Button(role: .destructive, action: clearTapped) {
				Label("Clear All Feedback", systemImage: "trash").frame(maxWidth: .infinity)
			}
			.buttonStyle(.bordered)
			.tint(.red)
			.padding()
			.background(.bar)
		}
	}

	// No confirmation once the tester has exported this session — they already have a copy.
	private func clearTapped() {
		if hasSharedThisSession { model.clearAll() } else { confirmingClear = true }
	}

	private static var trailing: ToolbarItemPlacement {
		#if canImport(UIKit)
		.topBarTrailing
		#else
		.primaryAction
		#endif
	}
}
