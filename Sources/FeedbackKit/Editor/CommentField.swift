//
//  CommentField.swift
//  FeedbackKit
//
//  The comment editor: a text field plus a mic button that dictates via TapeDeck.
//  Finalized speech is appended to the text; live tentative text shows dimmed below.
//

import SwiftUI

struct CommentField: View {
	@Binding var text: String
	var dictation: FeedbackDictation

	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			VStack(alignment: .leading, spacing: 2) {
				TextField("Describe the issue…", text: $text, axis: .vertical)
					.lineLimit(2...5)
					.textFieldStyle(.roundedBorder)

				if dictation.isRecording, !dictation.tentativeText.isEmpty {
					Text(dictation.tentativeText)
						.foregroundStyle(.secondary)
						.italic()
				}
			}

			Button(action: toggleDictation) {
				Image(systemName: dictation.isRecording ? "mic.fill" : "mic")
					.symbolRenderingMode(.multicolor)
					.contentTransition(.symbolEffect(.replace))
					.imageScale(.large)
			}
			.buttonStyle(.plain)
			.accessibilityLabel(dictation.isRecording ? "Stop dictation" : "Start dictation")
		}
		.padding()
		.background(.bar)
	}

	private func toggleDictation() {
		let binding = $text
		Task { await dictation.toggle { finalized in Self.append(finalized, to: binding) } }
	}

	private static func append(_ new: String, to text: Binding<String>) {
		guard !new.isEmpty else { return }
		if text.wrappedValue.isEmpty {
			text.wrappedValue = new
		} else {
			text.wrappedValue += text.wrappedValue.hasSuffix(" ") ? new : " " + new
		}
	}
}
