//
//  AnnotationShapes.swift
//  FeedbackKit
//
//  SwiftUI rendering of a single structured annotation during editing.
//

import SwiftUI

struct ArrowShape: Shape {
	let from: CGPoint
	let to: CGPoint

	func path(in rect: CGRect) -> Path {
		var path = Path()
		path.move(to: from)
		path.addLine(to: to)
		let angle = atan2(to.y - from.y, to.x - from.x)
		let head: CGFloat = 18
		for spread in [CGFloat.pi - .pi / 7, CGFloat.pi + .pi / 7] {
			path.move(to: to)
			path.addLine(to: CGPoint(x: to.x + head * cos(angle + spread), y: to.y + head * sin(angle + spread)))
		}
		return path
	}
}

struct AnnotationShape: View {
	let annotation: Annotation
	let size: CGSize

	var body: some View {
		let rect = annotation.rect(in: size)
		let from = CGPoint(x: annotation.start.x * size.width, y: annotation.start.y * size.height)
		let to = CGPoint(x: annotation.end.x * size.width, y: annotation.end.y * size.height)

		switch annotation.kind {
		case .box:
			Rectangle()
				.strokeBorder(annotation.color, lineWidth: 3)
				.frame(width: rect.width, height: rect.height)
				.position(x: rect.midX, y: rect.midY)
		case .arrow:
			ArrowShape(from: from, to: to)
				.stroke(annotation.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
				.frame(width: size.width, height: size.height)
		case .blur:
			RoundedRectangle(cornerRadius: 4)
				.fill(.ultraThinMaterial)
				.overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.secondary))
				.frame(width: rect.width, height: rect.height)
				.position(x: rect.midX, y: rect.midY)
		case .text:
			Text(annotation.text.isEmpty ? "Text" : annotation.text)
				.font(.headline.bold())
				.foregroundStyle(annotation.color)
				.position(x: from.x, y: from.y)
		}
	}
}
