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
                VStack(spacing: 16) {
                    ProgressView().tint(Theme.purple).scaleEffect(1.5)
                    Text("Extracting text...")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
            } else {
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
                
                VStack {
                    Spacer()
                    Button {
                        viewModel.requestCapture()
                    } label: {
                        Label("Capture Text", systemImage: "viewfinder")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.red, isFullWidth: true))
                    .disabled(viewModel.captureDisabled)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle("Scan Document")
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .textSelection:
                CapturedTextSelectionView(viewModel: viewModel)
            case .capturedText:
                CapturedTextSheet(viewModel: viewModel, onTextCaptured: onTextCaptured)
            }
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
