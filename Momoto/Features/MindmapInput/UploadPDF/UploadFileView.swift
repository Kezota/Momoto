//
//  UploadFileView.swift
//  MomotoMindmap
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct UploadFileView: View {
    @StateObject private var viewModel = UploadFileViewModel()
    @State private var showImporter = false
    @State private var hasAutoPrompted = false
    @Environment(\.dismiss) private var dismiss

    var onTextExtracted: (String) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                backButton
                    .padding(.top, 12)

                if viewModel.extractedText.isEmpty {
                    initialState
                } else {
                    previewState
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationBarHidden(true)
        .onAppear {
            if !hasAutoPrompted {
                hasAutoPrompted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showImporter = true
                }
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url): viewModel.handleURL(url)
            case .failure(let error): viewModel.errorMessage = error.localizedDescription
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

    private var initialState: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Upload a PDF")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            Spacer()

            pdfArt
                .padding(.bottom, 28)

            Text("We'll extract the text and turn it into a mindmap.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(Theme.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .transition(.opacity)
            }

            Spacer()

            Button {
                showImporter = true
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isWorking { ProgressView().tint(Theme.white) }
                    Text(viewModel.isWorking ? "Reading..." : "Choose PDF")
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
            .disabled(viewModel.isWorking)
        }
    }

    private var previewState: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preview of extracted text:")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.textSecondary)

            TextEditor(text: $viewModel.extractedText)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(16)
                .frame(maxHeight: .infinity)
                .background(Theme.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.stroke, lineWidth: 1))

            HStack(spacing: 12) {
                Button("Re-upload") {
                    viewModel.clear()
                    showImporter = true
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.purple))

                Button(action: {
                    onTextExtracted(viewModel.extractedText)
                }) {
                    Text("Make Mindmap")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
            }
        }
    }

    private var pdfArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.purple.opacity(0.12))
                .frame(width: 180, height: 180)

            VStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.purple)
                Text("PDF")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.purple)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UploadFileView(onTextExtracted: { _ in })
    }
}
