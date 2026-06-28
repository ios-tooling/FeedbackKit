//
//  MarkupCanvasView.swift
//  FeedbackKit
//
//  Composites the base capture, the freehand layer (PencilKit on iOS, SwiftUI Canvas on
//  macOS), and the structured annotation overlay, sized to the image's aspect-fit rect.
//

import SwiftUI
import CrossPlatformKit
#if canImport(UIKit)
import PencilKit
#endif

struct MarkupCanvasView: View {
	let image: UXImage
	#if canImport(UIKit)
	let canvas: PKCanvasView
	#endif
	@Bindable var store: MarkupStore
	let isCommenting: Bool
	@Binding var displaySize: CGSize

	// Mimic the system screenshot review screen: a rounded, inset capture on black.
	private static let inset: CGFloat = 18
	private static let cornerRadius: CGFloat = 24

	var body: some View {
		GeometryReader { geo in
			let fit = Self.fittedSize(image.size, in: geo.size)
			ZStack {
				ZStack {
					Image(uxImage: image).resizable().frame(width: fit.width, height: fit.height)
					freehandLayer(fit: fit)
					AnnotationOverlay(store: store, displaySize: fit)
						.allowsHitTesting(store.placesAnnotations && !isCommenting)
				}
				.frame(width: fit.width, height: fit.height)
				.clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))

				if store.tool == .crop || store.isCropped {
					CropOverlay(store: store, size: fit, isEditing: store.tool == .crop)
						.allowsHitTesting(store.tool == .crop && !isCommenting)
				}
			}
			.frame(width: fit.width, height: fit.height)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.onAppear { displaySize = fit }
			.onChange(of: geo.size) { _, newSize in displaySize = Self.fittedSize(image.size, in: newSize) }
		}
		.background(Color.black)
	}

	@ViewBuilder private func freehandLayer(fit: CGSize) -> some View {
		let active = store.isFreehand && !isCommenting
		#if canImport(UIKit)
		PencilCanvasRepresentable(canvas: canvas, isActive: active)
			.frame(width: fit.width, height: fit.height)
			.allowsHitTesting(active)
		#else
		FreehandCanvasView(store: store, isActive: active, size: fit)
			.frame(width: fit.width, height: fit.height)
			.allowsHitTesting(active)
		#endif
	}

	static func fittedSize(_ imageSize: CGSize, in available: CGSize) -> CGSize {
		let available = CGSize(width: available.width - inset * 2, height: available.height - inset * 2)
		guard imageSize.width > 0, imageSize.height > 0, available.width > 0, available.height > 0 else { return available }
		let scale = min(available.width / imageSize.width, available.height / imageSize.height)
		return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
	}
}
