//
//  SlackMessageTests.swift
//  FeedbackKitTests
//

import Testing
import Foundation
@testable import FeedbackKit

struct SlackMessageTests {
	@Test func messageIncludesCategoryScreenCommentAndDeviceLine() {
		var report = makeSampleReport(comment: "It crashed")
		report.category = .bug
		report.context = FeedbackContext(screenName: "CartScreen")
		report.userID = "user-7"

		let text = SlackMessage.text(for: report)

		#expect(text.contains("[Bug]"))
		#expect(text.contains("CartScreen"))
		#expect(text.contains("user-7"))
		#expect(text.contains("It crashed"))
		#expect(text.contains(report.metadata.appVersion))
	}

	@Test func messageOmitsEmptyCommentLine() {
		var report = makeSampleReport(comment: "")
		report.context = FeedbackContext(screenName: "Home")
		let text = SlackMessage.text(for: report)
		#expect(text.contains("Home"))
		// header + device line only
		#expect(text.split(separator: "\n").count == 2)
	}
}
