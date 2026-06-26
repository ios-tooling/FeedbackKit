//
//  SlackTransport.swift
//  FeedbackKit
//
//  Uploads the annotated screenshot inline to a Slack channel using the current
//  three-step external-upload flow (getUploadURLExternal → upload → completeUpload).
//  Requires a bot token with the `files:write` scope and a target channel id.
//

import Foundation

public struct SlackTransport: FeedbackTransport {
	public let name = "slack"
	let botToken: String
	let channelID: String

	public init(botToken: String, channelID: String) {
		self.botToken = botToken
		self.channelID = channelID
	}

	public func send(_ report: FeedbackReport) async throws {
		// Text-only report (no screenshot): post a plain message. Requires the
		// `chat:write` scope in addition to `files:write`.
		guard let image = report.annotatedImageData else {
			try await postMessage(SlackMessage.text(for: report))
			return
		}

		let filename = "feedback-\(report.id.uuidString).jpg"
		let upload = try await requestUploadURL(filename: filename, length: image.count)
		try await uploadBytes(image, to: upload.url)
		try await completeUpload(fileID: upload.id, title: filename, comment: SlackMessage.text(for: report))
	}

	// MARK: Text-only

	private func postMessage(_ text: String) async throws {
		var request = slackRequest("https://slack.com/api/chat.postMessage")
		request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
		request.httpBody = try JSONSerialization.data(withJSONObject: ["channel": channelID, "text": text])
		_ = try await run(request, as: SlackOK.self)
	}

	// MARK: Step 1

	private func requestUploadURL(filename: String, length: Int) async throws -> (url: String, id: String) {
		var request = slackRequest("https://slack.com/api/files.getUploadURLExternal")
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		request.httpBody = formBody(["filename": filename, "length": "\(length)"])
		let response = try await run(request, as: UploadURLResponse.self)
		guard let url = response.upload_url, let id = response.file_id else {
			throw SlackError(error: "missing upload_url/file_id")
		}
		return (url, id)
	}

	// MARK: Step 2

	private func uploadBytes(_ data: Data, to urlString: String) async throws {
		guard let url = URL(string: urlString) else { throw SlackError(error: "invalid upload_url") }
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
		let (body, response) = try await URLSession.shared.upload(for: request, from: data)
		try HTTP.validate(response, data: body)
	}

	// MARK: Step 3

	private func completeUpload(fileID: String, title: String, comment: String) async throws {
		var request = slackRequest("https://slack.com/api/files.completeUploadExternal")
		request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
		request.httpBody = try JSONSerialization.data(withJSONObject: [
			"files": [["id": fileID, "title": title]],
			"channel_id": channelID,
			"initial_comment": comment,
		])
		_ = try await run(request, as: SlackOK.self)
	}

	// MARK: Helpers

	private func slackRequest(_ urlString: String) -> URLRequest {
		var request = URLRequest(url: URL(string: urlString)!)
		request.httpMethod = "POST"
		request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
		return request
	}

	private func run<T: SlackResponse>(_ request: URLRequest, as: T.Type) async throws -> T {
		let (data, response) = try await URLSession.shared.data(for: request)
		try HTTP.validate(response, data: data)
		let decoded = try JSONDecoder().decode(T.self, from: data)
		guard decoded.ok else { throw SlackError(error: decoded.error ?? "unknown Slack error") }
		return decoded
	}

	private func formBody(_ params: [String: String]) -> Data {
		var components = URLComponents()
		components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
		return Data((components.percentEncodedQuery ?? "").utf8)
	}
}

public struct SlackError: LocalizedError {
	public let error: String
	public var errorDescription: String? { "Slack: \(error)" }
}

private protocol SlackResponse: Decodable { var ok: Bool { get }; var error: String? { get } }
private struct SlackOK: SlackResponse { let ok: Bool; let error: String? }
private struct UploadURLResponse: SlackResponse {
	let ok: Bool
	let error: String?
	let upload_url: String?
	let file_id: String?
}

enum SlackMessage {
	/// The text posted alongside the screenshot.
	static func text(for report: FeedbackReport) -> String {
		var lines = ["*[\(report.category.displayName)]* \(report.context.screenName ?? "Feedback")"]
		if let userID = report.userID { lines[0] += " — \(userID)" }
		if !report.comment.isEmpty { lines.append(report.comment) }
		let m = report.metadata
		lines.append("_\(m.osVersion) · \(m.deviceModel) · v\(m.appVersion) (\(m.appBuild))_")
		return lines.joined(separator: "\n")
	}
}
