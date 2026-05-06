//
//  UploadFileView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct UploadFileView: View {
    @StateObject private var viewModel = UploadFileViewModel()
    @State private var showImporter = false
    
    var onTextExtracted: (String) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                pdfArt

                Text("We'll extract the text and turn it into a mindmap.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(Theme.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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
                .buttonStyle(PrimaryButtonStyle(color: Theme.yellow, isFullWidth: true))
                .disabled(viewModel.isWorking)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Upload a PDF")
        .navigationBarTitleDisplayMode(.large)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url): viewModel.handleURL(url, onTextExtracted: onTextExtracted)
            case .failure(let error): viewModel.errorMessage = error.localizedDescription
            }
        }
    }

    private var pdfArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.yellow.opacity(0.15))
                .frame(width: 180, height: 220)
                .shadow(color: Theme.yellow.opacity(0.25), radius: 16, x: 0, y: 10)

            VStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 90, weight: .regular))
                    .foregroundStyle(Theme.yellow)
                Text("PDF")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.yellow)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UploadFileView(onTextExtracted: { _ in })
    }
}
