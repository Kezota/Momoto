//
//  PasteTextView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI
import UIKit

struct PasteTextView: View {
    @State private var text = ""
    @FocusState private var editorFocused: Bool
    
    var onSubmit: (String) -> Void
    private let minChars = 40

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("We'll summarise it into an interactive mindmap.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                editorCard

                Spacer(minLength: 0)

                Button("Generate Mindmap", action: submit)
                    .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
                    .disabled(text.count < minChars)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle("Paste your text")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .keyboard) { Spacer() }
            ToolbarItem(placement: .keyboard) {
                Button("Done") { editorFocused = false }
            }
        }
    }

    private var editorCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .shadow(color: Theme.black.opacity(0.04), radius: 12, x: 0, y: 6)

            TextEditor(text: $text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(14)
                .scrollContentBackground(.hidden)
                .focused($editorFocused)

            if text.isEmpty {
                Text("Paste a paragraph or two here...")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
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
