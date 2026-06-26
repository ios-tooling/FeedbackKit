//
//  CloudKitTransport.swift
//  FeedbackKit
//
//  Default review surface: stores each report as a CKRecord with the images as CKAssets.
//  Serverless — browse reports in the CloudKit dashboard (or a companion viewer later).
//

import Foundation
import CloudKit

public struct CloudKitTransport: FeedbackTransport {
	public let name = "cloudkit"
	public enum Scope: Sendable { case publicDatabase, privateDatabase }

	let containerID: String
	let scope: Scope
	let recordType: String

	public init(containerID: String, scope: Scope = .publicDatabase, recordType: String = "FeedbackReport") {
		self.containerID = containerID
		self.scope = scope
		self.recordType = recordType
	}

	public func send(_ report: FeedbackReport) async throws {
		let assets = try TempAssets(report: report)
		defer { assets.cleanUp() }

		let record = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: report.id.uuidString))
		record["comment"] = report.comment as CKRecordValue
		record["category"] = report.category.rawValue as CKRecordValue
		record["createdAt"] = report.createdAt as CKRecordValue
		record["screenName"] = (report.context.screenName ?? "") as CKRecordValue
		if let userID = report.userID { record["userID"] = userID as CKRecordValue }
		record["metadataJSON"] = jsonString(report.metadata) as CKRecordValue
		record["contextJSON"] = jsonString(report.context) as CKRecordValue
		if let breadcrumbs = report.breadcrumbs { record["breadcrumbsJSON"] = jsonString(breadcrumbs) as CKRecordValue }
		if let annotated = assets.annotated { record["annotatedImage"] = CKAsset(fileURL: annotated) }
		if let original = assets.original { record["originalImage"] = CKAsset(fileURL: original) }

		let database = CKContainer(identifier: containerID).database(with: scope.ckScope)
		_ = try await database.save(record)
	}

	private func jsonString<T: Encodable>(_ value: T) -> String {
		(try? JSONEncoder().encode(value)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
	}
}

private extension CloudKitTransport.Scope {
	var ckScope: CKDatabase.Scope {
		switch self {
		case .publicDatabase: .public
		case .privateDatabase: .private
		}
	}
}

/// Writes the report's JPEGs to temporary files so they can become CKAssets.
private struct TempAssets {
	let annotated: URL?
	let original: URL?
	private let directory: URL

	init(report: FeedbackReport) throws {
		directory = FileManager.default.temporaryDirectory.appendingPathComponent(report.id.uuidString, isDirectory: true)
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		if let annotatedData = report.annotatedImageData {
			let url = directory.appendingPathComponent("annotated.jpg")
			try annotatedData.write(to: url)
			annotated = url
		} else {
			annotated = nil
		}
		if let originalData = report.originalImageData {
			let url = directory.appendingPathComponent("original.jpg")
			try originalData.write(to: url)
			original = url
		} else {
			original = nil
		}
	}

	func cleanUp() {
		try? FileManager.default.removeItem(at: directory)
	}
}
