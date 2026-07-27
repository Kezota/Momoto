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

    var onTextExtracted: (String) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                initialState
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Upload PDF")
        .navigationBarTitleDisplayMode(.large)
        // `.task` is tied to the view's lifetime, so the prompt is cancelled if the user leaves
        // before it fires. The short wait lets the push animation settle before presenting.
        .task {
            guard !hasAutoPrompted else { return }
            hasAutoPrompted = true
            try? await Task.sleep(for: .milliseconds(350))
            showImporter = true
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url): viewModel.handleURL(url, onExtracted: onTextExtracted)
            case .failure(let error): viewModel.errorMessage = error.localizedDescription
            }
        }
    }
    
    private var initialState: some View {
        VStack(spacing: 0) {
            Spacer()

            pdfArt
                .padding(.bottom, 28)

            Text("We'll pull the text from your PDF.")
                .font(.system(.subheadline, design: .rounded))
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
