//
//  LocalCollectionTransport.swift
//  FeedbackKit
//
//  A transport that keeps feedback locally instead of sending it: each report is written
//  as a directory bundle into the collection store for later review and bulk export. Add it
//  alongside remote transports to both send and archive, or use it alone for a collect-only app.
//

import Foundation

public struct LocalCollectionTransport: FeedbackTransport {
	public var name: String { "collection" }

	/// Override the collection location; `nil` uses the shared default the export UI reads.
	private let directory: URL?

	public init(directory: URL? = nil) {
		self.directory = directory
	}

	public func send(_ report: FeedbackReport) async throws {
		let store = try FeedbackCollectionStore(directory: directory)
		try store.write(report)
	}
}
