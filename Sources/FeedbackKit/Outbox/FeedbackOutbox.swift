//
//  FeedbackOutbox.swift
//  FeedbackKit
//
//  Observable, main-actor manager around the store + sender. Submitting persists
//  instantly (so the editor can dismiss without waiting on the network) and kicks a
//  retrying background drain. Entries that exhaust in-session retries stay on disk and
//  are retried again on the next submit or app launch.
//

import SwiftUI
import Achtung
import Chronicle

@MainActor @Observable public final class FeedbackOutbox {
	public private(set) var pendingCount: Int
	public var maxRetriesPerRun = 5

	private let store: OutboxStore
	private let sender: OutboxSender
	private var isDraining = false

	public init(transport: FeedbackTransport, directory: URL? = nil) throws {
		store = try OutboxStore(directory: directory)
		sender = OutboxSender(store: store, transport: transport)
		pendingCount = store.count
	}

	/// Persist a finished report and start delivering. Returns immediately.
	public func submit(_ report: FeedbackReport) {
		do {
			try store.write(report)
			pendingCount = store.count
			Achtung.show(title: "Feedback queued", foreground: .secondary)
		} catch {
			Chronicle.error(error, description: "FeedbackKit failed to persist a report")
			Achtung.show(title: "Couldn't save feedback", error: error, foreground: .red)
			return
		}
		Task { await drain() }
	}

	/// Drain the queue, retrying failures with exponential backoff. Safe to call on launch.
	public func drain() async {
		guard !isDraining else { return }
		isDraining = true
		defer { isDraining = false }

		let startCount = pendingCount
		var attempt = 0
		while true {
			let failed = await sender.drainOnce()
			pendingCount = store.count

			if failed.isEmpty {
				if startCount > 0 && pendingCount == 0 {
					await Achtung.show(title: "Feedback sent", foreground: .green)
				}
				return
			}

			attempt += 1
			if attempt >= maxRetriesPerRun {
				await Achtung.show(title: "Feedback will retry later", message: "\(failed.count) pending", foreground: .orange)
				return
			}
			try? await Task.sleep(nanoseconds: backoffNanoseconds(attempt))
		}
	}

	private func backoffNanoseconds(_ attempt: Int) -> UInt64 {
		let seconds = min(60.0, 2.0 * pow(2.0, Double(attempt - 1)))
		return UInt64(seconds * 1_000_000_000)
	}
}
