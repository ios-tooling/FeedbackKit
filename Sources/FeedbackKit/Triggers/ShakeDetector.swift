//
//  ShakeDetector.swift
//  FeedbackKit
//
//  Global shake detection. UIWindow forwards an unhandled shake up the responder
//  chain; we post a notification the root modifier listens for via an async sequence.
//

import Foundation

public extension Notification.Name {
	static let feedbackKitDidShake = Notification.Name("FeedbackKitDidShake")
}

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIWindow {
	open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			NotificationCenter.default.post(name: .feedbackKitDidShake, object: nil)
		}
		super.motionEnded(motion, with: event)
	}
}
#endif
