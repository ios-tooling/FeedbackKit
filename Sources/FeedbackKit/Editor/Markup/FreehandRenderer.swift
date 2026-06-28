//
//  FreehandRenderer.swift
//  FeedbackKit
//
//  Rasterizes macOS freehand strokes to a UXImage at display size. ImageRenderer keeps the
//  orientation correct on its own, so the flattener can composite the result directly.
//

#if canImport(AppKit)
import SwiftUI
import AppKit
import CrossPlatformKit

@MainActor enum FreehandRenderer {
	static func image(strokes: [Stroke], size: CGSize) -> UXImage? {
		guard !strokes.isEmpty, size.width > 0, size.height > 0 else { return nil }
		let renderer = ImageRenderer(content: StrokesCanvas(strokes: strokes, size: size))
		renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
		return renderer.uxImage
	}
}
#endif
