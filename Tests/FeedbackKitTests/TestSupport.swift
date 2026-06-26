//
//  TestSupport.swift
//  FeedbackKitTests
//
//  Shared fixtures and mock transports for the test target.
//

import Foundation
@testable import FeedbackKit

actor CallRecorder {
	private(set) var names: [String] = []
	func record(_ name: String) { names.append(name) }
	var count: Int { names.count }
}

struct MockTransport: FeedbackTransport {
	let name: String
	let recorder: CallRecorder
	let shouldFail: Bool
	struct MockError: Error {}

	init(name: String, recorder: CallRecorder = CallRecorder(), shouldFail: Bool = false) {
		self.name = name
		self.recorder = recorder
		self.shouldFail = shouldFail
	}

	func send(_ report: FeedbackReport) async throws {
		await recorder.record(name)
		if shouldFail { throw MockError() }
	}
}

/// Fails its first `failures` sends, then succeeds — exercises retry/backoff.
actor FailCounter {
	private var remaining: Int
	init(_ failures: Int) { remaining = failures }
	func nextShouldFail() -> Bool {
		guard remaining > 0 else { return false }
		remaining -= 1
		return true
	}
}

struct FlakyTransport: FeedbackTransport {
	let name = "flaky"
	let counter: FailCounter
	struct FlakyError: Error {}

	func send(_ report: FeedbackReport) async throws {
		if await counter.nextShouldFail() { throw FlakyError() }
	}
}

func makeSampleReport(comment: String = "hi") -> FeedbackReport {
	FeedbackReport(
		id: UUID(),
		createdAt: Date(timeIntervalSince1970: 1),
		comment: comment,
		category: .bug,
		metadata: FeedbackMetadata(
			appVersion: "1", appBuild: "1", osVersion: "iOS", deviceName: "d",
			deviceModel: "m", idiom: "phone", locale: "en", timeZone: "UTC",
			screenSize: nil, orientation: nil, physicalMemory: 1, freeDiskBytes: nil,
			distribution: "development", isSimulator: true
		),
		annotatedImageData: Data([0x00])
	)
}

func makeTempDirectory() -> URL {
	FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
}
