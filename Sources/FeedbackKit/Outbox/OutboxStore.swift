//
//  OutboxStore.swift
//  FeedbackKit
//
//  On-disk persistence for pending reports. Each report is one self-contained JSON
//  file named for its id, so writing the same report twice is idempotent.
//

import Foundation
import Suite

public struct OutboxStore: Sendable {
	public let directory: URL

	public init(directory: URL? = nil) throws {
		self.directory = directory ?? FileManager.applicationSupportDirectory.appendingPathComponent("FeedbackKitOutbox", isDirectory: true)
		try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
	}

	@discardableResult public func write(_ report: FeedbackReport) throws -> URL {
		let url = directory.appendingPathComponent("\(report.id.uuidString).json")
		try JSONEncoder().encode(report).write(to: url, options: .atomic)
		return url
	}

	/// Pending entry file URLs, oldest first.
	public func entries() throws -> [URL] {
		let keys: [URLResourceKey] = [.creationDateKey]
		let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys)
			.filter { $0.pathExtension == "json" }
		return files.sorted { lhs, rhs in
			let l = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
			let r = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
			return l < r
		}
	}

	public func loadReport(at url: URL) throws -> FeedbackReport {
		try JSONDecoder().decode(FeedbackReport.self, from: Data(contentsOf: url))
	}

	public func remove(at url: URL) throws {
		try FileManager.default.removeItem(at: url)
	}

	public var count: Int { (try? entries().count) ?? 0 }
}
