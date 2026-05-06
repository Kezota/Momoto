//
//  PasteTextView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
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

            VStack(spacing: 8) {
                HStack {
                    Text("Paste your text")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                .padding(.top, 12)

                Text("We'll summarise it into an interactive mindmap.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)

                editorCard

                Spacer(minLength: 0)

                Button("Generate Mindmap", action: submit)
                    .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
                    .disabled(viewModel.isSubmitDisabled)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
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

            TextEditor(text: $viewModel.text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(14)
                .scrollContentBackground(.hidden)
                .focused($editorFocused)

            if viewModel.text.isEmpty {
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
        editorFocused = false
        viewModel.submit(onSubmit: onSubmit)
    }
}

#Preview {
    NavigationStack {
        PasteTextView(onSubmit: { _ in })
    }
}
