//
//  AnnotationOverlay.swift
//  FeedbackKit
//
//  Interactive layer for placing structured annotations. Active only when a non-draw
//  tool is selected; drag to draw arrows/boxes/blur regions, tap to drop text.
//

#if canImport(UIKit) && !os(watchOS)
import SwiftUI

struct AnnotationOverlay: View {
	@Bindable var store: MarkupStore
	let displaySize: CGSize

	@State private var draft: Annotation?
	@State private var pendingText: Annotation?
	@State private var textInput = ""

	var body: some View {
		ZStack {
			ForEach(store.annotations) { AnnotationShape(annotation: $0, size: displaySize) }
			if let draft { AnnotationShape(annotation: draft, size: displaySize) }
		}
		.frame(width: displaySize.width, height: displaySize.height)
		.contentShape(Rectangle())
		.gesture(placementGesture)
		.alert("Add text", isPresented: textAlertPresented) {
			TextField("Text", text: $textInput)
			Button("Add", action: commitText)
			Button("Cancel", role: .cancel) { pendingText = nil }
		}
	}

	private var placementGesture: some Gesture {
		DragGesture(minimumDistance: 0)
			.onChanged { value in
				guard !store.tool.isFreehand, store.tool != .text else { return }
				draft = Annotation(kind: kind(for: store.tool), start: normalize(value.startLocation), end: normalize(value.location), color: store.color)
			}
			.onEnded { value in
				guard !store.tool.isFreehand else { return }
				if store.tool == .text {
					pendingText = Annotation(kind: .text, start: normalize(value.location), end: normalize(value.location), color: store.color)
					textInput = ""
					return
				}
				if let draft { store.add(draft) }
				draft = nil
			}
	}

	private var textAlertPresented: Binding<Bool> {
		Binding(get: { pendingText != nil }, set: { if !$0 { pendingText = nil } })
	}

	private func commitText() {
		guard var annotation = pendingText, !textInput.isEmpty else { pendingText = nil; return }
		annotation.text = textInput
		store.add(annotation)
		pendingText = nil
	}

	private func kind(for tool: MarkupTool) -> Annotation.Kind {
		switch tool {
		case .arrow: .arrow
		case .box: .box
		case .blur: .blur
		default: .box
		}
	}

	private func normalize(_ point: CGPoint) -> CGPoint {
		CGPoint(x: min(max(point.x / displaySize.width, 0), 1), y: min(max(point.y / displaySize.height, 0), 1))
	}
}
#endif
