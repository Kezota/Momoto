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
    @State private var hasAutoPrompted = false
    
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
            }
        }
        .navigationTitle("Scan Document")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.isScannerPresented) {
            DocumentScannerView(
                onDidFinishWith: { images in
                    viewModel.isScannerPresented = false
                    viewModel.processScannedImages(images)
                },
                onDidCancel: {
                    viewModel.isScannerPresented = false
                    dismiss() // Go back to Home if user cancels scanner
                }
            )
            .ignoresSafeArea()
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
        .sheet(isPresented: $viewModel.showCapturedTextSheet) {
            CapturedTextSheet(viewModel: viewModel, onTextCaptured: onTextCaptured)
        }
        .onAppear {
            if !hasAutoPrompted {
                hasAutoPrompted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.isScannerPresented = true
                }
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
