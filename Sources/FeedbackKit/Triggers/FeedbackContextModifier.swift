//
//  FeedbackContextModifier.swift
//  FeedbackKit
//
//  `.feedbackContext("Screen", metadata: [...])` records where the user is, so reports
//  know which screen they came from. Resolved at capture time.
//

import SwiftUI

private struct FeedbackContextKey: EnvironmentKey {
	static let defaultValue = FeedbackContext.empty
}

extension EnvironmentValues {
	var feedbackContext: FeedbackContext {
		get { self[FeedbackContextKey.self] }
		set { self[FeedbackContextKey.self] = newValue }
	}
}

public extension View {
	func feedbackContext(_ screenName: String? = nil, metadata: [String: String] = [:]) -> some View {
		modifier(FeedbackContextModifier(context: FeedbackContext(screenName: screenName, metadata: metadata)))
	}
}

struct FeedbackContextModifier: ViewModifier {
	let context: FeedbackContext

	func body(content: Content) -> some View {
		content
			.environment(\.feedbackContext, context)
			.onAppear { FeedbackController.shared.currentContext = context }
	}
}
