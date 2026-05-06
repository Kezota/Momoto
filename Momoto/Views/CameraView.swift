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
    }
                                                                                                                    

}

// MARK: - Captured Text Sheet
private struct CapturedTextSheet: View {
    @ObservedObject var viewModel: CameraViewModel
    let onTextCaptured: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("We'll summarise it into an interactive mindmap.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 12)
                    
                    ScrollView {
                        Text(viewModel.ocr.scannedText)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(16)
                    }
                    .frame(maxHeight: .infinity)
                    .background(Theme.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
                    
                    HStack(spacing: 12) {
                        Button("Retake") {
                            viewModel.retake()
                            dismiss()
                        }
                        .buttonStyle(SecondaryButtonStyle(color: Theme.red))
                        
                        Button(action: {
                            dismiss()
                            viewModel.handleGenerate(onTextCaptured: onTextCaptured)
                        }) {
                            Text("Make Mindmap")
                        }
                        .buttonStyle(PrimaryButtonStyle(color: Theme.red, isFullWidth: true))
                        .disabled(viewModel.generateDisabled)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Captured Text")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}

#Preview {
    NavigationStack {
        CameraView { text in
            print("Preview captured text: \(text)")
        }
    }
}
