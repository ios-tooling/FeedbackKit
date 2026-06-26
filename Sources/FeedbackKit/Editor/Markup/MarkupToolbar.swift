//
//  MarkupToolbar.swift
//  FeedbackKit
//

#if canImport(UIKit) && !os(watchOS)
import SwiftUI

struct MarkupToolbar: View {
	@Bindable var store: MarkupStore

	var body: some View {
		HStack(spacing: 6) {
			ForEach(MarkupTool.allCases) { tool in
				Button { store.tool = tool } label: {
					Image(systemName: tool.symbolName)
						.font(.body.weight(.medium))
						.frame(width: 38, height: 38)
						.foregroundStyle(store.tool == tool ? Color.white : Color.primary)
						.background { if store.tool == tool { Circle().fill(.tint) } }
				}
			}
			Spacer(minLength: 8)
			ColorPicker("Color", selection: $store.color, supportsOpacity: false).labelsHidden()
			Button { store.undoLastAnnotation() } label: {
				Image(systemName: "arrow.uturn.backward")
			}
			.disabled(!store.hasAnnotations)
		}
		.padding(.horizontal)
		.padding(.vertical, 8)
		.background(.bar)
	}
}
#endif
