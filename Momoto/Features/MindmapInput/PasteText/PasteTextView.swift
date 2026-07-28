//
//  PasteTextView.swift
//  MomotoMindmap
//

import SwiftUI
import UIKit

struct PasteTextView: View {
    @StateObject private var viewModel = PasteTextViewModel()
    @FocusState private var editorFocused: Bool

    var onSubmit: (String) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Paste or type your text. You'll pick the style next.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Editor Card Container
                editorCard

                Spacer(minLength: 0)

                // Advances to the Personalize step rather than generating straight away.
                Button("Continue", action: submit)
                    .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
                    .disabled(viewModel.isSubmitDisabled)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Paste Text")
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
                .shadow(color: Theme.black.opacity(0.03), radius: 8, x: 0, y: 4)

            TextEditor(text: $viewModel.text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(16)
                .scrollContentBackground(.hidden)
                .focused($editorFocused)

            if viewModel.text.isEmpty {
                Text("Paste a paragraph or two here…")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 24)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func submit() {
        editorFocused = false
        viewModel.submit(onSubmit: onSubmit)
    }
}

#Preview {
    NavigationStack {
        PasteTextView(onSubmit: { _ in })
    }
}
