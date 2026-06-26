//
//  OutboxSender.swift
//  FeedbackKit
//
//  Drains the store through a transport. Headless and side-effect-light so it can be
//  tested directly; toasts and retry scheduling live in FeedbackOutbox.
//

import Foundation
import Chronicle

public struct OutboxSender: Sendable {
	let store: OutboxStore
	let transport: FeedbackTransport

	public init(store: OutboxStore, transport: FeedbackTransport) {
		self.store = store
		self.transport = transport
	}

	/// Attempts every pending entry once. Successful sends are deleted; undecodable
	/// "poison" entries are dropped (and logged) so they can't block forever. Returns
	/// the URLs that failed to send and remain queued.
	@discardableResult public func drainOnce() async -> [URL] {
		let urls = (try? store.entries()) ?? []
		var failed: [URL] = []

		for url in urls {
			let report: FeedbackReport
			do {
				report = try store.loadReport(at: url)
			} catch {
				Chronicle.error(error, description: "FeedbackKit dropped undecodable outbox entry")
				try? store.remove(at: url)
				continue
			}

			do {
				try await transport.send(report)
				try? store.remove(at: url)
			} catch {
				failed.append(url)
			}
		}
		return failed
	}
}
