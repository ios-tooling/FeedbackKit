//
//  MarkupCanvasView.swift
//  FeedbackKit
//
//  Composites the base capture, the PencilKit freehand layer, and the structured
//  annotation overlay, sized to the image's aspect-fit rect.
//

#if canImport(UIKit) && !os(watchOS)
import SwiftUI
import PencilKit
import CrossPlatformKit

struct MarkupCanvasView: View {
	let image: UXImage
	let canvas: PKCanvasView
	@Bindable var store: MarkupStore
	@Binding var displaySize: CGSize

	var body: some View {
		GeometryReader { geo in
			let fit = Self.fittedSize(image.size, in: geo.size)
			ZStack {
				Image(uiImage: image).resizable().frame(width: fit.width, height: fit.height)
				PencilCanvasRepresentable(canvas: canvas, isActive: store.tool.isFreehand)
					.frame(width: fit.width, height: fit.height)
					.allowsHitTesting(store.tool.isFreehand)
				AnnotationOverlay(store: store, displaySize: fit)
					.allowsHitTesting(!store.tool.isFreehand)
			}
			.frame(width: fit.width, height: fit.height)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.onAppear { displaySize = fit }
			.onChange(of: geo.size) { _, newSize in displaySize = Self.fittedSize(image.size, in: newSize) }
		}
		.background(Color(.secondarySystemBackground))
	}

	static func fittedSize(_ imageSize: CGSize, in available: CGSize) -> CGSize {
		guard imageSize.width > 0, imageSize.height > 0, available.width > 0, available.height > 0 else { return available }
		let scale = min(available.width / imageSize.width, available.height / imageSize.height)
		return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
	}
}
#endif
