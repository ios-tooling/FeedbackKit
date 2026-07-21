//
//  FeedbackDictation.swift
//  FeedbackKit
//
//  One mic control that drives TapeDeck's live transcriber and audio recorder together:
//  finalized speech is appended to the comment, the raw audio is saved to a temp .m4a
//  and later folded into the report.
//

import Foundation
import TapeDeck
import Chronicle

@MainActor @Observable final class FeedbackDictation {
	private(set) var isRecording = false
	private(set) var audioURL: URL?

	private let transcriber = Transcriber.instance
	private let recorder = AudioRecorder.instance
	private var utterancesTask: Task<Void, Never>?

	/// Live, not-yet-finalized text to show dimmed while dictating.
	var tentativeText: String { transcriber.isTranscribing ? transcriber.tentativeText : "" }

	/// Toggle dictation. `onFinalized` fires with each completed utterance so the caller
	/// can append it to the comment.
	func toggle(onFinalized: @escaping @MainActor (String) -> Void) async {
		if isRecording { await stop() } else { await start(onFinalized: onFinalized) }
	}

	private func start(onFinalized: @escaping @MainActor (String) -> Void) async {
		guard await TapeDeckPermissions.instance.requestMicrophone(),
			  await TapeDeckPermissions.instance.requestSpeechRecognition() else {
			Chronicle.track("feedbackkit_dictation_permission_denied")
			return
		}

		let url = FileManager.default.temporaryDirectory.appendingPathComponent("feedback-\(UUID().uuidString).m4a")
		do {
			try await recorder.record(to: url)
			transcriber.clear()
			try await transcriber.start()
		} catch {
			_ = try? await recorder.stop()
			Chronicle.error(error, description: "FeedbackKit failed to start dictation")
			return
		}

		audioURL = url
		isRecording = true
		utterancesTask = Task { for await utterance in transcriber.utterances() { onFinalized(utterance.text) } }
	}

	func stop() async {
		guard isRecording else { return }
		isRecording = false
		utterancesTask?.cancel()
		utterancesTask = nil
		await transcriber.stop()
		_ = try? await recorder.stop()
	}

	/// The recorded audio, ready to attach to a report. `nil` when nothing was recorded.
	func audioData() -> Data? {
		guard let audioURL else { return nil }
		return try? Data(contentsOf: audioURL)
	}

	/// Delete the temp recording — call when the tester cancels.
	func discard() {
		if let audioURL { try? FileManager.default.removeItem(at: audioURL) }
		audioURL = nil
	}
}
