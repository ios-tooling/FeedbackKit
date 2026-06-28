//
//  MarkupFlattener.swift
//  FeedbackKit
//
//  Renders base capture + freehand stroke layer + structured annotations into one image
//  at native resolution. Blur regions are genuinely pixellated for redaction.
//
//  Cross-platform: draws into an explicit bottom-left CGContext bitmap (sized to the base's
//  pixels) so the result is identical on UIKit and AppKit, with no graphics-context quirks.
//  The freehand layer is passed in pre-rendered (`strokeImage`) so this stays PencilKit-free.
//

import CoreGraphics
import CoreText
import CoreImage
import SwiftUI
import CrossPlatformKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum MarkupFlattener {
	@MainActor static func flatten(base: UXImage, strokeImage: UXImage?, annotations: [Annotation], displaySize: CGSize, cropRect: CGRect = MarkupStore.fullCrop) -> UXImage {
		guard let baseCG = base.cgImageRef else { return base }
		let pixelSize = CGSize(width: baseCG.width, height: baseCG.height)
		guard let ctx = makeContext(pixelSize) else { return base }

		ctx.interpolationQuality = .high
		let full = CGRect(origin: .zero, size: pixelSize)
		ctx.draw(baseCG, in: full)
		if let strokeCG = strokeImage?.cgImageRef { ctx.draw(strokeCG, in: full) }
		for annotation in annotations { draw(annotation, base: baseCG, pixelSize: pixelSize, in: ctx) }

		guard let rendered = ctx.makeImage() else { return base }
		return UXImage(cgImage: cropped(rendered, to: cropRect))
	}

	private static func makeContext(_ size: CGSize) -> CGContext? {
		CGContext(data: nil, width: Int(size.width), height: Int(size.height),
				  bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
				  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
	}

	private static func cropped(_ image: CGImage, to cropRect: CGRect) -> CGImage {
		guard cropRect != MarkupStore.fullCrop else { return image }
		let pixel = CGRect(x: cropRect.minX * CGFloat(image.width), y: cropRect.minY * CGFloat(image.height),
						   width: cropRect.width * CGFloat(image.width), height: cropRect.height * CGFloat(image.height)).integral
		return image.cropping(to: pixel) ?? image
	}

	// MARK: - Annotation drawing (normalized top-left coords → bottom-left CG context)

	private static func draw(_ annotation: Annotation, base: CGImage, pixelSize: CGSize, in ctx: CGContext) {
		let cgColor = UXColor(annotation.color).cgColor
		let topLeftRect = annotation.rect(in: pixelSize)
		let from = pixelPoint(annotation.start, in: pixelSize)
		let to = pixelPoint(annotation.end, in: pixelSize)
		let width = max(3, pixelSize.width / 250)

		switch annotation.kind {
		case .box:
			ctx.setStrokeColor(cgColor); ctx.setLineWidth(width); ctx.stroke(flip(topLeftRect, in: pixelSize))
		case .arrow:
			drawArrow(from: from, to: to, color: cgColor, width: width, in: ctx)
		case .text:
			drawText(annotation.text, topLeft: from, color: annotation.color, pixelSize: pixelSize, in: ctx)
		case .blur:
			drawRedaction(topLeftRect: topLeftRect, base: base, pixelSize: pixelSize, in: ctx)
		}
	}

	/// Convert a normalized top-left point to a bottom-left pixel point.
	private static func pixelPoint(_ p: CGPoint, in size: CGSize) -> CGPoint {
		CGPoint(x: p.x * size.width, y: size.height - p.y * size.height)
	}

	/// Flip a top-left pixel rect into the context's bottom-left coordinate space.
	private static func flip(_ rect: CGRect, in size: CGSize) -> CGRect {
		CGRect(x: rect.minX, y: size.height - rect.maxY, width: rect.width, height: rect.height)
	}

	private static func drawArrow(from: CGPoint, to: CGPoint, color: CGColor, width: CGFloat, in ctx: CGContext) {
		ctx.setStrokeColor(color); ctx.setLineWidth(width); ctx.setLineCap(.round)
		ctx.move(to: from); ctx.addLine(to: to)
		let angle = atan2(to.y - from.y, to.x - from.x)
		let head = max(18, width * 5)
		for spread in [CGFloat.pi - .pi / 7, CGFloat.pi + .pi / 7] {
			ctx.move(to: to)
			ctx.addLine(to: CGPoint(x: to.x + head * cos(angle + spread), y: to.y + head * sin(angle + spread)))
		}
		ctx.strokePath()
	}

	private static func drawText(_ text: String, topLeft: CGPoint, color: Color, pixelSize: CGSize, in ctx: CGContext) {
		guard !text.isEmpty else { return }
		let font = UXFont.boldSystemFont(ofSize: max(18, pixelSize.width / 30))
		let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UXColor(color)]
		let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
		var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
		_ = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
		// `topLeft.y` is already bottom-left (top edge of the glyph box); drop to the baseline.
		ctx.textPosition = CGPoint(x: topLeft.x, y: topLeft.y - ascent)
		CTLineDraw(line, ctx)
	}

	private static func drawRedaction(topLeftRect rect: CGRect, base: CGImage, pixelSize: CGSize, in ctx: CGContext) {
		let target = flip(rect, in: pixelSize)
		func solid() {
			ctx.setFillColor(UXColor(white: 0.08, alpha: 1).cgColor)
			ctx.fill(target)
		}
		guard rect.width > 2, rect.height > 2, let region = base.cropping(to: rect.integral) else { return solid() }
		let input = CIImage(cgImage: region)
		guard let filter = CIFilter(name: "CIPixellate") else { return solid() }
		filter.setValue(input, forKey: kCIInputImageKey)
		filter.setValue(max(8, rect.width / 12), forKey: kCIInputScaleKey)
		let ciContext = CIContext()
		guard let output = filter.outputImage, let result = ciContext.createCGImage(output, from: input.extent) else { return solid() }
		ctx.draw(result, in: target)
	}
}
