//
//  HTTPTransport.swift
//  FeedbackKit
//
//  Generic escape hatch: POSTs the whole report as a JSON body (images ride along
//  as base64) to any host-controlled endpoint. The server you point at decides what
//  to do with it.
//

import Foundation

public struct HTTPTransport: FeedbackTransport {
	public let name = "http"
	let endpoint: URL
	let extraHeaders: [String: String]

	public init(endpoint: URL, headers: [String: String] = [:]) {
		self.endpoint = endpoint
		self.extraHeaders = headers
	}

	public func send(_ report: FeedbackReport) async throws {
		var request = URLRequest(url: endpoint)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		for (key, value) in extraHeaders { request.setValue(value, forHTTPHeaderField: key) }

		let body = try JSONEncoder().encode(report)
		let (data, response) = try await URLSession.shared.upload(for: request, from: body)
		try HTTP.validate(response, data: data)
	}
}
