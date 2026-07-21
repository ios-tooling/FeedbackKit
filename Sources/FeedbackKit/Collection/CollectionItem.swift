//
//  CollectionItem.swift
//  FeedbackKit
//
//  One feedback bundle on disk: a directory holding feedback.json (the report with its
//  media stripped) plus sidecar screenshot.jpg / original.jpg / audio.m4a files.
//

import Foundation

public struct CollectionItem: Identifiable, Sendable {
	public let directory: URL
	/// The report with image/audio `Data` stripped — those live as sidecar files.
	public let report: FeedbackReport

	public var id: UUID { report.id }
	public var createdAt: Date { report.createdAt }
	public var comment: String { report.comment }
	public var category: FeedbackCategory { report.category }

	public var screenshotURL: URL? { fileIfExists("screenshot.jpg") }
	public var originalURL: URL? { fileIfExists("original.jpg") }
	public var audioURL: URL? { fileIfExists("audio.m4a") }

	/// Decode a bundle directory; `nil` if it has no readable feedback.json.
	public init?(directory: URL) {
		let manifest = directory.appendingPathComponent("feedback.json")
		guard let data = try? Data(contentsOf: manifest),
			  let report = try? JSONDecoder().decode(FeedbackReport.self, from: data) else { return nil }
		self.directory = directory
		self.report = report
	}

	private func fileIfExists(_ name: String) -> URL? {
		let url = directory.appendingPathComponent(name)
		return FileManager.default.fileExists(atPath: url.path) ? url : nil
	}
}
