//
//  FeedbackMetadata.swift
//  FeedbackKit
//
//  Auto-collected device/app diagnostics attached to every report.
//

import Foundation
import Suite

#if canImport(UIKit)
import UIKit
#endif

public struct FeedbackMetadata: Codable, Sendable, Equatable {
	public var appVersion: String
	public var appBuild: String
	public var osVersion: String
	public var deviceName: String
	public var deviceModel: String
	public var idiom: String
	public var locale: String
	public var timeZone: String
	public var screenSize: CGSize?
	public var orientation: String?
	public var physicalMemory: UInt64
	public var freeDiskBytes: Int64?
	public var distribution: String
	public var isSimulator: Bool
}
