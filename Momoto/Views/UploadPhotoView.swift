//
//  UploadPhotoView.swift
//  MomotoMindmap
//

import SwiftUI
import PhotosUI

struct UploadPhotoView: View {
    
    @StateObject private var viewModel = UploadPhotoViewModel()
    @State private var hasAutoPrompted = false
    @State private var showPicker = false
    
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
        .navigationTitle("Use Photo")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if !hasAutoPrompted {
                hasAutoPrompted = true
                showPicker = true
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $viewModel.selectedItem, matching: .images, photoLibrary: .shared())
    }
    
    private var initialState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            photoArt
            
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
                showPicker = true
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isWorking { ProgressView().tint(Theme.white) }
                    Text(viewModel.isWorking ? "Reading..." : "Choose Photo")
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.cardHistory, isFullWidth: true))
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
                    showPicker = true
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.cardHistory))
                
                Button(action: {
                    onTextExtracted(viewModel.extractedText)
                }) {
                    Text("Make Mindmap")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.cardHistory, isFullWidth: true))
            }
        }
    }
    
    private var photoArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.cardHistory.opacity(0.15))
                .frame(width: 180, height: 220)
                .shadow(color: Theme.cardHistory.opacity(0.25), radius: 16, x: 0, y: 10)
            
            VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 90, weight: .regular))
                    .foregroundStyle(Theme.cardHistory)
                Text("PHOTO")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.cardHistory)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UploadPhotoView(onTextExtracted: { _ in })
    }
}
