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

            VStack(alignment: .leading, spacing: 20) {
                initialState
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Use Photo")
        .navigationBarTitleDisplayMode(.large)
        // `.task` is tied to the view's lifetime, so the prompt is cancelled if the user leaves
        // before it fires. The short wait lets the push animation settle before presenting.
        .task {
            guard !hasAutoPrompted else { return }
            hasAutoPrompted = true
            try? await Task.sleep(for: .milliseconds(350))
            showPicker = true
        }
        .photosPicker(isPresented: $showPicker, selection: $viewModel.selectedItem, matching: .images, photoLibrary: .shared())
        .onChange(of: viewModel.selectedItem) {
            _, newItem in guard let newItem else { return }
            viewModel.handleSelectedItem(newItem, onExtracted: onTextExtracted)
        }
    }

    private var initialState: some View {
        VStack(spacing: 0) {
            Spacer()

            photoArt
                .padding(.bottom, 28)

            Text("We'll read the text from your photo.")
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
                showPicker = true
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isWorking { ProgressView().tint(Theme.white) }
                    Text(viewModel.isWorking ? "Reading..." : "Choose Photo")
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
            .disabled(viewModel.isWorking)
        }
    }

    private var photoArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.purple.opacity(0.12))
                .frame(width: 180, height: 180)

            VStack(spacing: 12) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.purple)
                Text("PHOTO")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.purple)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UploadPhotoView(onTextExtracted: { _ in })
    }
}
