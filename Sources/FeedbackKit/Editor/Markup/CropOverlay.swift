//
//  CropOverlay.swift
//  FeedbackKit
//
//  Interactive crop frame shown when the crop tool is active: drag the corner/edge
//  handles to set the crop, dimming the area outside. The crop is stored normalized
//  on the store and applied by the flattener at send time.
//

#if canImport(UIKit) && !os(watchOS)
import SwiftUI

struct CropOverlay: View {
	@Bindable var store: MarkupStore
	let size: CGSize
	/// True while the crop tool is active: dim (so the rest of the image stays visible to
	/// reframe) and show handles. When inactive the crop persists as a solid mask so the
	/// image reads as cropped under any tool.
	let isEditing: Bool
	@State private var dragStart: CGRect?

	// Normalized anchors for the 8 handles (corners + edge midpoints); centre excluded.
	private let handles: [CGPoint] = [
		CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0),
		CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5),
		CGPoint(x: 0, y: 1), CGPoint(x: 0.5, y: 1), CGPoint(x: 1, y: 1),
	]

	var body: some View {
		let rect = displayRect
		ZStack(alignment: .topLeading) {
			Canvas { context, _ in
				var scrim = Path(CGRect(origin: .zero, size: size))
				scrim.addRect(rect)
				context.fill(scrim, with: .color(.black.opacity(isEditing ? 0.5 : 1)), style: FillStyle(eoFill: true))
				context.stroke(Path(rect), with: .color(.white.opacity(isEditing ? 1 : 0.7)), lineWidth: 1)
			}

			if isEditing {
				ForEach(handles.indices, id: \.self) { index in
					handle
						.position(x: rect.minX + handles[index].x * rect.width,
								  y: rect.minY + handles[index].y * rect.height)
						.gesture(drag(for: handles[index]))
				}

				if store.isCropped {
					Button("Reset") { withAnimation { store.resetCrop() } }
						.font(.caption.bold())
						.buttonStyle(.borderedProminent)
						.padding(8)
				}
			}
		}
		.frame(width: size.width, height: size.height)
	}

	private var handle: some View {
		Circle().fill(.white).frame(width: 14, height: 14).shadow(radius: 1)
			.frame(width: 44, height: 44)
			.contentShape(Rectangle())
	}

	private var displayRect: CGRect {
		CGRect(x: store.cropRect.minX * size.width, y: store.cropRect.minY * size.height,
			   width: store.cropRect.width * size.width, height: store.cropRect.height * size.height)
	}

	private func drag(for anchor: CGPoint) -> some Gesture {
		DragGesture()
			.onChanged { value in
				let start = dragStart ?? store.cropRect
				if dragStart == nil { dragStart = start }
				store.cropRect = adjusted(start, anchor: anchor, translation: value.translation)
			}
			.onEnded { _ in dragStart = nil }
	}

	private func adjusted(_ start: CGRect, anchor: CGPoint, translation: CGSize) -> CGRect {
		let minSize: CGFloat = 0.12
		var minX = start.minX, minY = start.minY, maxX = start.maxX, maxY = start.maxY
		let dx = translation.width / size.width
		let dy = translation.height / size.height
		if anchor.x == 0 { minX = min(max(0, start.minX + dx), maxX - minSize) }
		if anchor.x == 1 { maxX = max(min(1, start.maxX + dx), minX + minSize) }
		if anchor.y == 0 { minY = min(max(0, start.minY + dy), maxY - minSize) }
		if anchor.y == 1 { maxY = max(min(1, start.maxY + dy), minY + minSize) }
		return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
	}
}
#endif
