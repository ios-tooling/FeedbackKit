//
//  FeedbackTriggers.swift
//  FeedbackKit
//

import Foundation

/// The set of gestures/affordances a host enables to invoke the feedback flow.
public struct FeedbackTriggers: OptionSet, Sendable {
	public let rawValue: Int
	public init(rawValue: Int) { self.rawValue = rawValue }

	/// Shake the device (classic beta-tool trigger). **iOS only.**
	public static let shake = FeedbackTriggers(rawValue: 1 << 0)
	/// A draggable, always-visible bubble.
	public static let floatingButton = FeedbackTriggers(rawValue: 1 << 1)
	/// A two/three-finger long-press. **iOS only.**
	public static let multiFingerGesture = FeedbackTriggers(rawValue: 1 << 2)
	/// Host-driven invocation via `FeedbackKit.trigger()`.
	public static let programmatic = FeedbackTriggers(rawValue: 1 << 3)
	/// A ⌘⇧F keyboard shortcut. **macOS only** (no-op where unsupported).
	public static let keyboardShortcut = FeedbackTriggers(rawValue: 1 << 4)

	/// Sensible default for internal builds. Shake is ignored on platforms without it.
	public static let `default`: FeedbackTriggers = [.shake, .keyboardShortcut, .programmatic]
}
