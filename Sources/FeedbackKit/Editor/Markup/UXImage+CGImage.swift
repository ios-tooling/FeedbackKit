//
//  UXImage+CGImage.swift
//  FeedbackKit
//
//  A uniform `cgImage` accessor across UIKit and AppKit so the flattener and freehand
//  renderer can read pixels without per-platform branching at every call site.
//

import CoreGraphics
import CrossPlatformKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension UXImage {
	var cgImageRef: CGImage? {
		#if canImport(UIKit)
		cgImage
		#else
		cgImage(forProposedRect: nil, context: nil, hints: nil)
		#endif
	}
}
