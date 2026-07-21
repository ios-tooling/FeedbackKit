//
//  SharedReport.swift
//  FeedbackKit
//
//  Makes a single collected report shareable via a plain SwiftUI `ShareLink`: the report's
//  bundle is zipped only when the user actually shares it, off the main actor.
//

import SwiftUI
import UniformTypeIdentifiers

struct SharedReport: Transferable {
	let item: CollectionItem

	static var transferRepresentation: some TransferRepresentation {
		FileRepresentation(exportedContentType: .zip) { shared in
			SentTransferredFile(try FeedbackCollectionStore.zip(directory: shared.item.directory, named: FeedbackCollectionStore.defaultArchiveName))
		}
	}
}
