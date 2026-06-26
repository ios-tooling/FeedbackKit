//
//  FeedbackMetadataTests.swift
//  FeedbackKitTests
//

import Testing
import Foundation
@testable import FeedbackKit

@MainActor
struct FeedbackMetadataTests {
	@Test func currentPopulatesEnvironmentFields() {
		let metadata = FeedbackMetadata.current()

		#expect(!metadata.locale.isEmpty)
		#expect(!metadata.timeZone.isEmpty)
		#expect(!metadata.osVersion.isEmpty)
		#expect(metadata.physicalMemory > 0)
		#expect(!metadata.distribution.isEmpty)
	}

	@Test func currentSurvivesJSONRoundTrip() throws {
		let metadata = FeedbackMetadata.current()
		let data = try JSONEncoder().encode(metadata)
		let decoded = try JSONDecoder().decode(FeedbackMetadata.self, from: data)
		#expect(decoded == metadata)
	}
}
