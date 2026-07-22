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
    @Environment(\.dismiss) private var dismiss
    
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
                    topOverlay
                    bottomOverlay
                case .textSelection:
                    CapturedTextSelectionView(viewModel: viewModel)
                case .capturedText:
                    EditPreviewView(viewModel: viewModel, onTextCaptured: onTextCaptured)
                }
            }
        }
        .navigationBarHidden(true)
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
    
    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Theme.purple).scaleEffect(1.5)
            Text("Extracting text...")
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
    
    private var topOverlay: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white))
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
        }
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