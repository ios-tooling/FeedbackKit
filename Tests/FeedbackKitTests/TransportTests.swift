//
//  TransportTests.swift
//  FeedbackKitTests
//

import Testing
import Foundation
@testable import FeedbackKit

struct TransportTests {
	@Test func multiTransportFansOutToEveryTransport() async throws {
		let recorder = CallRecorder()
		let multi = MultiTransport([
			MockTransport(name: "a", recorder: recorder),
			MockTransport(name: "b", recorder: recorder),
			MockTransport(name: "c", recorder: recorder),
		])

		try await multi.send(makeSampleReport())

		let sent = await recorder.names
		#expect(Set(sent) == ["a", "b", "c"])
	}

	@Test func multiTransportThrowsAggregateWhenAnyFail() async {
		let recorder = CallRecorder()
		let multi = MultiTransport([
			MockTransport(name: "ok", recorder: recorder),
			MockTransport(name: "bad", recorder: recorder, shouldFail: true),
		])

		await #expect(throws: MultiTransportError.self) {
			try await multi.send(makeSampleReport())
		}

		// Both transports were still attempted (at-least-once fan-out).
		let sent = await recorder.names
		#expect(Set(sent) == ["ok", "bad"])
	}
}
