//
//  PasteTextView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI
import UIKit

struct PasteTextView: View {
    @State private var text: String = ""
    @FocusState private var editorFocused: Bool
    
    var onSubmit: (String) -> Void

    private let minChars = 40

    var body: some View {
        ZStack {
            Color(uiColor: UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste your text")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Text("We'll summarise it into an interactive mindmap.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                editorCard

                Spacer(minLength: 0)

                Button {
                    submit()
                } label: {
                    Text("Generate Mindmap")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .disabled(text.count < minChars)
                .opacity(text.count < minChars ? 0.55 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Spacer()
            }
            ToolbarItem(placement: .keyboard) {
                Button("Done") { editorFocused = false }
            }
        }
    }

    private var editorCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(uiColor: UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)

            TextEditor(text: $text)
                .font(.system(.body, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .scrollContentBackground(.hidden)
                .focused($editorFocused)

            if text.isEmpty {
                Text("Paste a paragraph or two here...")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 22)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: 320)
    }

    private func submit() {
        guard text.count >= minChars else { return }
        editorFocused = false
        onSubmit(text)
    }
}

#Preview {
    NavigationStack {
        PasteTextView(onSubmit: { _ in })
    }
}
