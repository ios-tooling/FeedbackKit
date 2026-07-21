//
//  CommentField.swift
//  FeedbackKit
//
//  The comment editor: a text field plus a mic button that dictates via TapeDeck. Finalized
//  speech is appended to the text; live tentative text streams inline at reduced opacity.
//  The field holds a fixed two-line height in both states so it never resizes mid-dictation.
//

import SwiftUI

struct CommentField: View {
	@Binding var text: String
	var dictation: FeedbackDictation

	var body: some View {
		HStack(alignment: .center) {
			field
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

	// One shared container for both states, its height pinned by an invisible two-line sizer so
	// it never resizes when dictation starts or stops — a TextField and a Text don't report the
	// same intrinsic height, so we can't rely on reservesSpace alone. While dictating it shows a
	// live preview (tentative tail dimmed), since a TextField can't style part of its text.
	@ViewBuilder private var field: some View {
		ZStack(alignment: .topLeading) {
			Text(verbatim: " \n ")
				.lineLimit(2, reservesSpace: true)
				.hidden()
				.accessibilityHidden(true)

			if dictation.isRecording {
				Text(livePreview)
					.lineLimit(2)
					.truncationMode(.head)
					.frame(maxWidth: .infinity, alignment: .topLeading)
			} else {
				TextField("Describe the issue…", text: $text, axis: .vertical)
					.textFieldStyle(.plain)
					.lineLimit(2)
			}
		}
		.frame(maxWidth: .infinity, alignment: .topLeading)
		.padding(EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8))
		.background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
		.overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.tertiary))
	}

	/// Committed text at full strength, followed by the live tentative words dimmed inline.
	private var livePreview: AttributedString {
		var result = AttributedString(text)
		let tentative = dictation.tentativeText
		if !tentative.isEmpty {
			var tail = AttributedString((text.isEmpty ? "" : " ") + tentative)
			tail.foregroundColor = .primary.opacity(0.4)
			result.append(tail)
		}
		return result
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
