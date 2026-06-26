//
//  HTTPSupport.swift
//  FeedbackKit
//
//  Small URLSession helpers shared by the HTTP and Slack transports. We use
//  URLSession directly (rather than Convey) because Convey's shipped API only
//  exposes a single shared `ConveyServer.default`; borrowing it would clobber the
//  host app's networking configuration, and an unconfigured server fails silently.
//

import Foundation

public struct FeedbackHTTPError: LocalizedError {
	public let statusCode: Int
	public let body: String
	public var errorDescription: String? { "HTTP \(statusCode): \(body)" }
}

enum HTTP {
	/// Throws `FeedbackHTTPError` for any non-2xx response.
	static func validate(_ response: URLResponse, data: Data) throws {
		guard let http = response as? HTTPURLResponse else { return }
		guard (200..<300).contains(http.statusCode) else {
			throw FeedbackHTTPError(statusCode: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
		}
	}
}
