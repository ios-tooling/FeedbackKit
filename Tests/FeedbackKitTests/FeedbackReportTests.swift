//
//  FeedbackReportTests.swift
//  FeedbackKitTests
//

import Testing
import Foundation
@testable import FeedbackKit

struct FeedbackReportTests {
	private func sampleMetadata() -> FeedbackMetadata {
		FeedbackMetadata(
			appVersion: "1.2", appBuild: "34", osVersion: "iOS 17.0",
			deviceName: "Test Phone", deviceModel: "iPhone", idiom: "phone",
			locale: "en_US", timeZone: "America/New_York",
			screenSize: CGSize(width: 390, height: 844), orientation: "portrait",
			physicalMemory: 4_000_000_000, freeDiskBytes: 12_345,
			distribution: "development", isSimulator: true
		)
	}

	@Test func reportRoundTripsThroughJSON() throws {
		let original = FeedbackReport(
			id: UUID(),
			createdAt: Date(timeIntervalSince1970: 1_000),
			comment: "Button is misaligned",
			category: .bug,
			metadata: sampleMetadata(),
			context: FeedbackContext(screenName: "CartScreen", metadata: ["cartID": "42"]),
			userID: "user-7",
			breadcrumbs: [BreadcrumbSummary(name: "tapped_checkout", timestamp: Date(timeIntervalSince1970: 999))],
			annotatedImageData: Data([0x01, 0x02, 0x03]),
			originalImageData: Data([0x09, 0x08])
		)

		let data = try JSONEncoder().encode(original)
		let decoded = try JSONDecoder().decode(FeedbackReport.self, from: data)

		#expect(decoded == original)
	}

	@Test func categoryExposesAllCasesWithDisplayNames() {
		#expect(FeedbackCategory.allCases.count == 3)
		#expect(FeedbackCategory.bug.displayName == "Bug")
		#expect(!FeedbackCategory.idea.symbolName.isEmpty)
	}

	@Test func emptyContextHasNoScreenOrMetadata() {
		#expect(FeedbackContext.empty.screenName == nil)
		#expect(FeedbackContext.empty.metadata.isEmpty)
	}

	@Test func defaultTriggersAreShakeAndProgrammatic() {
		#expect(FeedbackTriggers.default.contains(.shake))
		#expect(FeedbackTriggers.default.contains(.programmatic))
		#expect(!FeedbackTriggers.default.contains(.floatingButton))
	}
}
