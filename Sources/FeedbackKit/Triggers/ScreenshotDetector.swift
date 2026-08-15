//
//  ScreenshotDetector.swift
//  FeedbackKit
//
//  Fires the feedback flow when the user takes a system screenshot. iOS tells us the
//  screenshot happened but never hands us the image, so we re-grab the scene ourselves
//  instead of reading the user's photo library. Reading it would mean a photo permission
//  prompt, a race against the asset landing in the library, an outright failure under
//  limited-access, and — to clean up after ourselves — a system "allow deletion?" alert on
//  every single screenshot, since the asset isn't one we created. Re-capturing costs none
//  of that; the system's copy simply stays in Photos where the user expects it.
//

import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit

enum ScreenshotDetector {
	/// Screenshots taken while the app is frontmost. The notification carries no image.
	static var events: NotificationCenter.Notifications {
		NotificationCenter.default.notifications(named: UIApplication.userDidTakeScreenshotNotification)
	}
}
#endif
