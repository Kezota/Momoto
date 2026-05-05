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
    @State private var showImporter: Bool = false
    @State private var errorMessage: String?
    @State private var isWorking: Bool = false
    
    var onTextExtracted: (String) -> Void

    var body: some View {
        ZStack {
            Color(uiColor: UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Upload a PDF")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)

                Spacer()

                pdfArt

                VStack(spacing: 8) {
                    Text("Upload a PDF")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Text("We'll extract the text and turn it into a mindmap.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }

                Spacer()

                Button {
                    showImporter = true
                } label: {
                    HStack(spacing: 10) {
                        if isWorking {
                            ProgressView().tint(.white)
                        }
                        Text(isWorking ? "Reading..." : "Choose PDF")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .disabled(isWorking)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.pdf]
        ) { result in
            switch result {
            case .success(let url):
                handleURL(url)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private var pdfArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.orange.opacity(0.15))
                .frame(width: 180, height: 220)
                .shadow(color: Color.orange.opacity(0.25), radius: 16, x: 0, y: 10)

            VStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 90, weight: .regular))
                    .foregroundStyle(Color.orange)
                Text("PDF")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.orange)
            }
        }
    }

    private func handleURL(_ url: URL) {
        errorMessage = nil
        isWorking = true

        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        let text = PDFTextService.extract(from: url)
        isWorking = false

        guard !text.isEmpty else {
            errorMessage = "No readable text found in this PDF."
            return
        }

        onTextExtracted(text)
    }
}

#Preview {
    NavigationStack {
        UploadFileView(onTextExtracted: { _ in })
    }
}
