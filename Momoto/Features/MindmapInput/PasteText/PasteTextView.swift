//
//  PasteTextView.swift
//  MomotoMindmap
//

import SwiftUI
import UIKit

struct PasteTextView: View {
    @StateObject private var viewModel = PasteTextViewModel()
    @FocusState private var editorFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var onSubmit: (String) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Top Bar / Back Button
                backButton
                    .padding(.top, 12)
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text("Paste your text")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("We'll summarise it into an interactive mindmap.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                // Editor Card Container
                editorCard
                
                Spacer(minLength: 0)
                
                // Bottom Primary Button
                Button("Generate Mindmap", action: submit)
                    .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
                    .disabled(viewModel.isSubmitDisabled)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .keyboard) { Spacer() }
            ToolbarItem(placement: .keyboard) {
                Button("Done") { editorFocused = false }
            }
        }
    }
    
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.05))
                .clipShape(Circle())
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
                Text("Paste a paragraph or two here..")
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
