//
//  OutboxTests.swift
//  FeedbackKitTests
//

import Testing
import Foundation
@testable import FeedbackKit

struct OutboxTests {
	@Test func storeWritesReloadsAndRemoves() throws {
		let store = try OutboxStore(directory: makeTempDirectory())
		let report = makeSampleReport(comment: "persist me")
		let url = try store.write(report)

		#expect(store.count == 1)
		let loaded = try store.loadReport(at: url)
		#expect(loaded.comment == "persist me")

		try store.remove(at: url)
		#expect(store.count == 0)
	}

	@Test func writingSameReportIsIdempotent() throws {
		let store = try OutboxStore(directory: makeTempDirectory())
		let report = makeSampleReport()
		try store.write(report)
		try store.write(report)
		#expect(store.count == 1)
	}

	@Test func senderDeliversAndEmptiesStore() async throws {
		let store = try OutboxStore(directory: makeTempDirectory())
		try store.write(makeSampleReport())
		try store.write(makeSampleReport())

		let sender = OutboxSender(store: store, transport: MockTransport(name: "ok"))
		let failed = await sender.drainOnce()

		#expect(failed.isEmpty)
		#expect(store.count == 0)
	}

	@Test func failedSendStaysQueued() async throws {
		let store = try OutboxStore(directory: makeTempDirectory())
		try store.write(makeSampleReport())

		let sender = OutboxSender(store: store, transport: MockTransport(name: "bad", shouldFail: true))
		let failed = await sender.drainOnce()

		#expect(failed.count == 1)
		#expect(store.count == 1)
	}

	@Test func flakyTransportSucceedsOnRetry() async throws {
		let store = try OutboxStore(directory: makeTempDirectory())
		try store.write(makeSampleReport())

		let sender = OutboxSender(store: store, transport: FlakyTransport(counter: FailCounter(1)))

		let first = await sender.drainOnce()
		#expect(first.count == 1)        // first attempt fails, stays queued
		#expect(store.count == 1)

		let second = await sender.drainOnce()
		#expect(second.isEmpty)          // retry succeeds
		#expect(store.count == 0)
	}

	@Test func poisonEntryIsDroppedNotRetriedForever() async throws {
		let dir = makeTempDirectory()
		let store = try OutboxStore(directory: dir)
		try Data("not json".utf8).write(to: dir.appendingPathComponent("\(UUID().uuidString).json"))

		let sender = OutboxSender(store: store, transport: MockTransport(name: "ok"))
		let failed = await sender.drainOnce()

		#expect(failed.isEmpty)
		#expect(store.count == 0)
	}

	@MainActor @Test func outboxSubmitPersistsAndDrainsToEmpty() async throws {
		let outbox = try FeedbackOutbox(transport: MockTransport(name: "ok"), directory: makeTempDirectory())
		outbox.submit(makeSampleReport())
		#expect(outbox.pendingCount == 1)   // persisted synchronously, before any await

		// submit() kicks a background drain; wait for it to flush.
		var tries = 0
		while outbox.pendingCount > 0 && tries < 200 {
			try? await Task.sleep(nanoseconds: 5_000_000)
			tries += 1
		}
		#expect(outbox.pendingCount == 0)
	}
}
