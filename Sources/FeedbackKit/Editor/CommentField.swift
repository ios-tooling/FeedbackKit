//
//  CommentField.swift
//  FeedbackKit
//

import SwiftUI

struct CommentField: View {
	@Binding var text: String

	var body: some View {
		TextField("Describe the issue…", text: $text, axis: .vertical)
			.lineLimit(2...5)
			.textFieldStyle(.roundedBorder)
			.padding()
			.background(.bar)
	}
}
