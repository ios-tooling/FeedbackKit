//
//  MultiTransport.swift
//  FeedbackKit
//
//  Fans a report out to several transports concurrently. Delivery is at-least-once:
//  if any transport fails the whole send throws, so the outbox retries — which may
//  re-deliver to transports that already succeeded. Acceptable for internal use.
//

import Foundation

public struct MultiTransport: FeedbackTransport {
	public let name = "multi"
	public let transports: [FeedbackTransport]

	public init(_ transports: [FeedbackTransport]) {
		self.transports = transports
	}

	public func send(_ report: FeedbackReport) async throws {
		let failures = await withTaskGroup(of: TransportFailure?.self) { group in
			for transport in transports {
				group.addTask {
					do {
						try await transport.send(report)
						return nil
					} catch {
						return TransportFailure(transport: transport.name, error: error)
					}
				}
			}
			var collected: [TransportFailure] = []
			for await failure in group where failure != nil {
				collected.append(failure!)
			}
			return collected
		}

		if !failures.isEmpty { throw MultiTransportError(failures: failures) }
	}
}

public struct TransportFailure: Sendable {
	public let transport: String
	public let error: any Error
}

public struct MultiTransportError: Error {
	public let failures: [TransportFailure]
	public var localizedDescription: String {
		"FeedbackKit: \(failures.count) transport(s) failed: "
			+ failures.map { "\($0.transport): \($0.error.localizedDescription)" }.joined(separator: "; ")
	}
}
