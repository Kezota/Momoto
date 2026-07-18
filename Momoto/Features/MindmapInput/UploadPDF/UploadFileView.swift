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
    @State private var hasAutoPrompted = false
    
    var onTextExtracted: (String) -> Void
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                if viewModel.extractedText.isEmpty {
                    initialState
                } else {
                    previewState
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Upload a PDF")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if !hasAutoPrompted {
                hasAutoPrompted = true
                showImporter = true
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url): viewModel.handleURL(url)
            case .failure(let error): viewModel.errorMessage = error.localizedDescription
            }
        }
    }
    
    private var initialState: some View {
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
    }
    
    private var previewState: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preview of extracted text:")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 12)
            
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
                .buttonStyle(SecondaryButtonStyle(color: Theme.yellow))
                
                Button(action: {
                    onTextExtracted(viewModel.extractedText)
                }) {
                    Text("Make Mindmap")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.yellow, isFullWidth: true))
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
