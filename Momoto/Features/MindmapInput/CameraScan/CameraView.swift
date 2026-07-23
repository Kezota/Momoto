//
//  CameraView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI
import UIKit

struct CameraView: View {
    let onTextCaptured: (String) -> Void
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            if viewModel.ocr.isProcessing {
                processingView
            } else {
                switch viewModel.phase {
                case .scanning:
                    scannerLayer
                    blackBars
                    bottomOverlay
                case .textSelection:
                    CapturedTextSelectionView(viewModel: viewModel)
                case .capturedText:
                    EditPreviewView(viewModel: viewModel, onTextCaptured: onTextCaptured)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        // The crop/selection step is an immersive editor over the captured image and keeps its
        // own floating controls; every other phase uses the standard navigation bar.
        .toolbar(viewModel.phase == .textSelection ? .hidden : .visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(isCameraLive ? .dark : nil, for: .navigationBar)
        // In the review step "back" means re-scan, not leave the scanner.
        .navigationBarBackButtonHidden(viewModel.phase == .capturedText)
        .toolbar {
            if viewModel.phase == .capturedText {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Rescan", systemImage: "chevron.left") {
                        viewModel.retake()
                    }
                }
            }
        }
        .alert(
            "Couldn't read the text",
            isPresented: Binding(
                get: { viewModel.hasError },
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.retake() }
        } message: {
            Text(viewModel.ocr.errorMessage ?? "")
        }
    }
    
    /// True only while the live camera feed is on screen, where the bar sits over dark bands.
    private var isCameraLive: Bool {
        !viewModel.ocr.isProcessing
        && viewModel.phase != .textSelection
        && viewModel.phase != .capturedText
    }

    private var navigationTitle: String {
        switch viewModel.phase {
        case .capturedText: return "Review Text"
        default: return "Scan"
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Theme.purple).scaleEffect(1.5)
            Text("Reading the text…")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
    }
    
    private var scannerLayer: some View {
        LiveTextScannerView(
            captureRequestID: $viewModel.captureRequestID,
            onTextSectionsChanged: { sections in
                viewModel.updateRecognizedTextSections(sections)
            },
            onImageCaptured: { image, sections, previewSize in
                viewModel.handleCapturedImage(image, sections: sections, previewSize: previewSize)
            },
            onUnavailable: {
                viewModel.handleScannerUnavailable()
            }
        )
        .ignoresSafeArea()
    }
    
    private var blackBars: some View {
        GeometryReader { geometry in
            let bandHeight = geometry.size.height * (1 - viewModel.visibleHeightRatio) / 2
            VStack(spacing: 0) {
                Color.black
                    .frame(height: bandHeight)
                Spacer(minLength: 0)
                Color.black
                    .frame(height: bandHeight)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private var bottomOverlay: some View {
        VStack {
            Spacer()
            Button {
                viewModel.requestCapture()
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                }
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .disabled(viewModel.captureDisabled)
            .opacity(viewModel.captureDisabled ? 0.55 : 1)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    NavigationStack {
        CameraView { text in
            print("Preview captured text: \(text)")
        }
    }
}