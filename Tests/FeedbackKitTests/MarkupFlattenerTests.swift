//
//  MarkupFlattenerTests.swift
//  FeedbackKitTests
//
//  Exercises the cross-platform flattener (and the macOS freehand renderer) on the host.
//

import Testing
import CoreGraphics
import SwiftUI
import CrossPlatformKit
@testable import FeedbackKit

@MainActor
struct MarkupFlattenerTests {
	private func solidImage(width: Int, height: Int) -> UXImage {
		let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
							space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
		ctx.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1))
		ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
		return UXImage(cgImage: ctx.makeImage()!)
	}

	@Test func flattenWithBoxKeepsBasePixelSize() {
		let base = solidImage(width: 200, height: 120)
		let box = Annotation(kind: .box, start: CGPoint(x: 0.1, y: 0.1), end: CGPoint(x: 0.6, y: 0.7), color: .red)
		let result = MarkupFlattener.flatten(base: base, strokeImage: nil, annotations: [box], displaySize: CGSize(width: 200, height: 120))

		let cg = result.cgImageRef
		#expect(cg?.width == 200)
		#expect(cg?.height == 120)
	}

	@Test func cropShrinksOutputToTheCropRect() {
		let base = solidImage(width: 200, height: 120)
		let crop = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
		let result = MarkupFlattener.flatten(base: base, strokeImage: nil, annotations: [], displaySize: CGSize(width: 200, height: 120), cropRect: crop)

		let cg = result.cgImageRef
		#expect(cg?.width == 100)
		#expect(cg?.height == 60)
	}

	@Test func emptyFlattenReturnsBaseSize() {
		let base = solidImage(width: 64, height: 64)
		let result = MarkupFlattener.flatten(base: base, strokeImage: nil, annotations: [], displaySize: CGSize(width: 64, height: 64))

		#expect(result.cgImageRef?.width == 64)
		#expect(result.cgImageRef?.height == 64)
	}

	#if canImport(AppKit)
	@Test func freehandRendererProducesAnImage() {
		let strokes = [Stroke(points: [CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.9, y: 0.9)], color: .red)]
		let image = FreehandRenderer.image(strokes: strokes, size: CGSize(width: 100, height: 80))
		#expect(image != nil)
	}

	@Test func freehandRendererReturnsNilForNoStrokes() {
		#expect(FreehandRenderer.image(strokes: [], size: CGSize(width: 100, height: 80)) == nil)
	}
	#endif
}
