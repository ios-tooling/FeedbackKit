//
//  FeedbackCollectionStore.swift
//  FeedbackKit
//
//  On-disk store for the local "collect and export later" route. Each report becomes a
//  self-contained directory bundle; the whole store zips to a single file for sharing.
//

import Foundation
import Suite

public struct FeedbackCollectionStore: Sendable {
	public let directory: URL

	public init(directory: URL? = nil) throws {
		self.directory = directory ?? FileManager.applicationSupportDirectory.appendingPathComponent("FeedbackKitCollection", isDirectory: true)
		try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
	}

	/// Write one report as a directory bundle: media as sidecar files, everything else in feedback.json.
	@discardableResult public func write(_ report: FeedbackReport) throws -> URL {
		let bundle = directory.appendingPathComponent(report.id.uuidString, isDirectory: true)
		try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)

		try report.annotatedImageData?.write(to: bundle.appendingPathComponent("screenshot.jpg"), options: .atomic)
		try report.originalImageData?.write(to: bundle.appendingPathComponent("original.jpg"), options: .atomic)
		try report.audioData?.write(to: bundle.appendingPathComponent("audio.m4a"), options: .atomic)

		var manifest = report
		manifest.annotatedImageData = nil
		manifest.originalImageData = nil
		manifest.audioData = nil
		try JSONEncoder().encode(manifest).write(to: bundle.appendingPathComponent("feedback.json"), options: .atomic)
		return bundle
	}

	/// Collected items, newest first.
	public func items() -> [CollectionItem] {
		let bundles = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
		return bundles.compactMap(CollectionItem.init(directory:)).sorted { $0.createdAt > $1.createdAt }
	}

	public var isEmpty: Bool { items().isEmpty }

	public func remove(_ id: UUID) throws {
		try FileManager.default.removeItem(at: directory.appendingPathComponent(id.uuidString, isDirectory: true))
	}

	/// Delete every bundle in the collection (including any unreadable leftovers).
	public func removeAll() throws {
		for url in (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [] {
			try FileManager.default.removeItem(at: url)
		}
	}

	/// The default share name, e.g. "MyApp Feedback".
	public static var defaultArchiveName: String {
		let display = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
		let app = display ?? Bundle.main.name
		return "\(app.isEmpty ? "App" : app) Feedback"
	}

	/// Zip the whole collection to a temp file, returning its URL for sharing.
	public func zipArchive(named name: String? = nil) throws -> URL {
		try Self.zip(directory: directory, named: name ?? Self.defaultArchiveName)
	}

	/// Zip one directory — the whole collection or a single report bundle — to a temp file.
	public static func zip(directory: URL, named name: String) throws -> URL {
		let destination = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).zip")
		try? FileManager.default.removeItem(at: destination)

		var coordinatorError: NSError?
		var thrown: Error?
		NSFileCoordinator().coordinate(readingItemAt: directory, options: .forUploading, error: &coordinatorError) { zipped in
			do { try FileManager.default.copyItem(at: zipped, to: destination) } catch { thrown = error }
		}
		if let coordinatorError { throw coordinatorError }
		if let thrown { throw thrown }
		return destination
	}
}
