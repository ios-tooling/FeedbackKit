//
//  FreehandCanvasView.swift
//  FeedbackKit
//
//  macOS freehand drawing. PencilKit is iOS-only, so the draw tool here is a SwiftUI
//  Canvas plus a drag gesture that collects normalized points into `MarkupStore.strokes`.
//

#if canImport(AppKit)
import SwiftUI

/// Renders committed strokes; shared by the live editor and the flatten-time renderer so
/// what you draw matches what gets sent.
struct StrokesCanvas: View {
	let strokes: [Stroke]
	let size: CGSize

	var body: some View {
		Canvas { context, _ in
			for stroke in strokes { draw(stroke, in: context) }
		}
		.frame(width: size.width, height: size.height)
	}

	private func draw(_ stroke: Stroke, in context: GraphicsContext) {
		guard let first = stroke.points.first else { return }
		var path = Path()
		path.move(to: denormalize(first))
		for point in stroke.points.dropFirst() { path.addLine(to: denormalize(point)) }
		context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.width, lineCap: .round, lineJoin: .round))
	}

	private func denormalize(_ p: CGPoint) -> CGPoint {
		CGPoint(x: p.x * size.width, y: p.y * size.height)
	}
}

struct FreehandCanvasView: View {
	@Bindable var store: MarkupStore
	let isActive: Bool
	let size: CGSize
	@State private var draft: Stroke?

	var body: some View {
		StrokesCanvas(strokes: store.strokes + [draft].compactMap { $0 }, size: size)
			.contentShape(Rectangle())
			.gesture(isActive ? drawGesture : nil)
	}

	private var drawGesture: some Gesture {
		DragGesture(minimumDistance: 0)
			.onChanged { value in
				let point = normalize(value.location)
				if draft == nil { draft = Stroke(points: [point], color: store.color) }
				else { draft?.points.append(point) }
			}
			.onEnded { _ in
				if let draft, draft.points.count > 1 { store.add(draft) }
				draft = nil
			}
	}

	private func normalize(_ p: CGPoint) -> CGPoint {
		CGPoint(x: min(max(p.x / size.width, 0), 1), y: min(max(p.y / size.height, 0), 1))
	}
}
#endif
