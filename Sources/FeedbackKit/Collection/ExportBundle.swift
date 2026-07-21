//
//  ExportBundle.swift
//  FeedbackKit
//
//  Builds the "Export All" archive on demand: every saved bundle plus the current in-progress
//  report (only if the tester has added text, audio, or markup), zipped into one shareable file.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportBundle: Transferable {
	/// The live draft to fold in, when present and non-empty. `nil` for the standalone screen.
	let currentDraft: FeedbackDraftEditing?

	static var transferRepresentation: some TransferRepresentation {
		FileRepresentation(exportedContentType: .zip) { bundle in
			SentTransferredFile(try await bundle.makeArchive())
		}
	}

	func makeArchive() async throws -> URL {
		let collection = try FeedbackCollectionStore()
		let staging = FileManager.default.temporaryDirectory.appendingPathComponent("FeedbackExport-\(UUID().uuidString)", isDirectory: true)
		try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)

		for item in collection.items() {
			try FileManager.default.copyItem(at: item.directory, to: staging.appendingPathComponent(item.id.uuidString, isDirectory: true))
		}

		// buildReport() flattens markup on the main actor; hop there via the @MainActor type.
		if let report = await currentDraft?.reportForExport() {
			try FeedbackCollectionStore(directory: staging).write(report)
		}

		return try FeedbackCollectionStore.zip(directory: staging, named: FeedbackCollectionStore.defaultArchiveName)
	}
}
