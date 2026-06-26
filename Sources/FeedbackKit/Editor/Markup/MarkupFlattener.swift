//
//  MarkupFlattener.swift
//  FeedbackKit
//
//  Renders base capture + PencilKit strokes + structured annotations into one image
//  at native resolution. Blur regions are genuinely pixellated for redaction.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit
import PencilKit
import CrossPlatformKit

enum MarkupFlattener {
	@MainActor static func flatten(base: UXImage, drawing: PKDrawing, annotations: [Annotation], displaySize: CGSize, cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> UXImage {
		let size = base.size
		let format = UIGraphicsImageRendererFormat.default()
		format.scale = base.scale
		let renderer = UIGraphicsImageRenderer(size: size, format: format)

		let full = renderer.image { context in
			let cg = context.cgContext
			base.draw(in: CGRect(origin: .zero, size: size))

			if !drawing.bounds.isEmpty, displaySize.width > 0 {
				let scale = size.width / displaySize.width
				let strokes = drawing.image(from: CGRect(origin: .zero, size: displaySize), scale: scale)
				strokes.draw(in: CGRect(origin: .zero, size: size))
			}

			for annotation in annotations { draw(annotation, base: base, imageSize: size, in: cg) }
		}

		return cropped(full, to: cropRect)
	}

	private static func cropped(_ image: UXImage, to cropRect: CGRect) -> UXImage {
		guard cropRect != CGRect(x: 0, y: 0, width: 1, height: 1), let cg = image.cgImage else { return image }
		let pixel = CGRect(x: cropRect.minX * CGFloat(cg.width), y: cropRect.minY * CGFloat(cg.height),
						   width: cropRect.width * CGFloat(cg.width), height: cropRect.height * CGFloat(cg.height)).integral
		guard let slice = cg.cropping(to: pixel) else { return image }
		return UIImage(cgImage: slice, scale: image.scale, orientation: image.imageOrientation)
	}

	private static func draw(_ annotation: Annotation, base: UXImage, imageSize: CGSize, in cg: CGContext) {
		let color = UIColor(annotation.color)
		let rect = annotation.rect(in: imageSize)
		let from = CGPoint(x: annotation.start.x * imageSize.width, y: annotation.start.y * imageSize.height)
		let to = CGPoint(x: annotation.end.x * imageSize.width, y: annotation.end.y * imageSize.height)
		let width = max(3, imageSize.width / 250)

		switch annotation.kind {
		case .box:
			cg.setStrokeColor(color.cgColor); cg.setLineWidth(width); cg.stroke(rect)
		case .arrow:
			drawArrow(from: from, to: to, color: color, width: width, in: cg)
		case .text:
			drawText(annotation.text, at: from, color: color, imageSize: imageSize)
		case .blur:
			drawRedaction(rect: rect, base: base)
		}
	}

	private static func drawArrow(from: CGPoint, to: CGPoint, color: UIColor, width: CGFloat, in cg: CGContext) {
		cg.setStrokeColor(color.cgColor); cg.setLineWidth(width); cg.setLineCap(.round)
		cg.move(to: from); cg.addLine(to: to)
		let angle = atan2(to.y - from.y, to.x - from.x)
		let head = max(18, width * 5)
		for spread in [CGFloat.pi - .pi / 7, CGFloat.pi + .pi / 7] {
			cg.move(to: to)
			cg.addLine(to: CGPoint(x: to.x + head * cos(angle + spread), y: to.y + head * sin(angle + spread)))
		}
		cg.strokePath()
	}

	private static func drawText(_ text: String, at point: CGPoint, color: UIColor, imageSize: CGSize) {
		guard !text.isEmpty else { return }
		let attrs: [NSAttributedString.Key: Any] = [
			.font: UIFont.boldSystemFont(ofSize: max(18, imageSize.width / 30)),
			.foregroundColor: color,
		]
		(text as NSString).draw(at: point, withAttributes: attrs)
	}

	private static func drawRedaction(rect: CGRect, base: UXImage) {
		func solid() {
			UIColor(white: 0.08, alpha: 1).setFill()
			UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
		}
		guard let cgImage = base.cgImage, rect.width > 2, rect.height > 2 else { return solid() }
		let scale = base.scale
		let pixelRect = CGRect(x: rect.minX * scale, y: rect.minY * scale, width: rect.width * scale, height: rect.height * scale).integral
		guard let cropped = cgImage.cropping(to: pixelRect) else { return solid() }

		let input = CIImage(cgImage: cropped)
		let filter = CIFilter(name: "CIPixellate")
		filter?.setValue(input, forKey: kCIInputImageKey)
		filter?.setValue(max(8, pixelRect.width / 12), forKey: kCIInputScaleKey)
		let ciContext = CIContext()
		guard let output = filter?.outputImage, let result = ciContext.createCGImage(output, from: input.extent) else { return solid() }
		UIImage(cgImage: result).draw(in: rect)
	}
}
#endif
