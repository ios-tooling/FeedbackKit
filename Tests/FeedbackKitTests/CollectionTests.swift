//
//  CollectionTests.swift
//  FeedbackKitTests
//
//  The local collection route: directory bundling, listing, removal, zip export, and the
//  transport that feeds it — plus the report's new audio field.
//

import Testing
import Foundation
@testable import FeedbackKit

struct CollectionTests {
	private func report(comment: String, createdAt: Date, audio: Data? = nil) -> FeedbackReport {
		FeedbackReport(
			id: UUID(), createdAt: createdAt, comment: comment, category: .idea,
			metadata: makeSampleReport().metadata,
			annotatedImageData: Data([0xFF]), originalImageData: Data([0xAA]), audioData: audio
		)
	}

	@Test func writeCreatesBundleWithSidecars() throws {
		let store = try FeedbackCollectionStore(directory: makeTempDirectory())
		let bundle = try store.write(report(comment: "bundle me", createdAt: Date(timeIntervalSince1970: 10), audio: Data([0x01, 0x02])))

		#expect(FileManager.default.fileExists(atPath: bundle.appendingPathComponent("screenshot.jpg").path))
		#expect(FileManager.default.fileExists(atPath: bundle.appendingPathComponent("original.jpg").path))
		#expect(FileManager.default.fileExists(atPath: bundle.appendingPathComponent("audio.m4a").path))

		// The media is stripped from feedback.json — it lives as sidecar files instead.
		let manifest = try JSONDecoder().decode(FeedbackReport.self, from: Data(contentsOf: bundle.appendingPathComponent("feedback.json")))
		#expect(manifest.comment == "bundle me")
		#expect(manifest.annotatedImageData == nil)
		#expect(manifest.audioData == nil)
	}

	@Test func itemsListNewestFirst() throws {
		let store = try FeedbackCollectionStore(directory: makeTempDirectory())
		try store.write(report(comment: "older", createdAt: Date(timeIntervalSince1970: 100)))
		try store.write(report(comment: "newer", createdAt: Date(timeIntervalSince1970: 200)))

		let items = store.items()
		#expect(items.count == 2)
		#expect(items.first?.comment == "newer")
		#expect(items.first?.screenshotURL != nil)
	}

	@Test func removeDeletesBundle() throws {
		let store = try FeedbackCollectionStore(directory: makeTempDirectory())
		let entry = report(comment: "x", createdAt: Date(timeIntervalSince1970: 1))
		try store.write(entry)
		#expect(store.items().count == 1)

		try store.remove(entry.id)
		#expect(store.isEmpty)
	}

	@Test func zipArchiveProducesNonEmptyFile() throws {
		let store = try FeedbackCollectionStore(directory: makeTempDirectory())
		try store.write(report(comment: "zip", createdAt: Date(timeIntervalSince1970: 1)))

		let zip = try store.zipArchive(named: "TestFeedback-\(UUID().uuidString)")
		defer { try? FileManager.default.removeItem(at: zip) }
		#expect(FileManager.default.fileExists(atPath: zip.path))
		#expect((try zip.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) > 0)
	}

	@Test func transportWritesBundle() async throws {
		let dir = makeTempDirectory()
		try await LocalCollectionTransport(directory: dir).send(report(comment: "via transport", createdAt: Date(timeIntervalSince1970: 5), audio: Data([0x09])))

		let items = try FeedbackCollectionStore(directory: dir).items()
		#expect(items.count == 1)
		#expect(items.first?.audioURL != nil)
	}

	@Test func reportRoundTripsAudioData() throws {
		let original = report(comment: "audio", createdAt: Date(timeIntervalSince1970: 3), audio: Data([0x1, 0x2, 0x3]))
		let decoded = try JSONDecoder().decode(FeedbackReport.self, from: JSONEncoder().encode(original))
		#expect(decoded.audioData == Data([0x1, 0x2, 0x3]))
		#expect(decoded == original)
	}
}
