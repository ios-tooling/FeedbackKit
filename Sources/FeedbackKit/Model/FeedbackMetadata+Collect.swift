//
//  FeedbackMetadata+Collect.swift
//  FeedbackKit
//

import Foundation
import Suite

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension FeedbackMetadata {
	/// Snapshots the current device/app state. Must run on the main actor because
	/// `Gestalt` and screen metrics are main-actor isolated.
	@MainActor static func current() -> FeedbackMetadata {
		let bundle = Bundle.main
		return FeedbackMetadata(
			appVersion: bundle.version,
			appBuild: bundle.buildNumber,
			osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
			deviceName: Gestalt.deviceName,
			deviceModel: deviceModel,
			idiom: idiom,
			locale: Locale.current.identifier,
			timeZone: TimeZone.current.identifier,
			screenSize: screenSize,
			orientation: orientation,
			physicalMemory: ProcessInfo.processInfo.physicalMemory,
			freeDiskBytes: freeDiskBytes,
			distribution: "\(Gestalt.distribution)",
			isSimulator: Gestalt.isOnSimulator
		)
	}

	@MainActor private static var deviceModel: String {
		#if canImport(UIKit)
		UIDevice.current.model
		#else
		"Mac"
		#endif
	}

	@MainActor private static var idiom: String {
		if Gestalt.isOnIPad { return "pad" }
		if Gestalt.isOnIPhone { return "phone" }
		if Gestalt.isOnMac { return "mac" }
		return "unknown"
	}

	@MainActor private static var screenSize: CGSize? {
		#if canImport(UIKit)
		UIScreen.main.bounds.size
		#elseif canImport(AppKit)
		NSScreen.main?.frame.size
		#else
		nil
		#endif
	}

	@MainActor private static var orientation: String? {
		guard let size = screenSize else { return nil }
		return size.width > size.height ? "landscape" : "portrait"
	}

	private static var freeDiskBytes: Int64? {
		let url = FileManager.documentsDirectory
		let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
		return values?.volumeAvailableCapacityForImportantUsage
	}
}
