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

    @StateObject private var camera = CameraSessionService()
    @StateObject private var ocr    = OCRViewModel()
    @State private var capturedImage: UIImage?
                                                                                                                
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                cameraArea
                textArea
                Spacer(minLength: 0)
                buttonRow.padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .navigationTitle("Scan with Camera")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { camera.bootstrap() }
        .onDisappear { camera.stop() }
        .alert(
            "Couldn't read the text",
            isPresented: Binding(
                get: { ocr.errorMessage != nil },
                set: { if !$0 { ocr.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(ocr.errorMessage ?? "")
        }
    }

    // MARK: - Camera Area
    
    @ViewBuilder
    private var cameraArea: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let capturedImage {
                    Image(uiImage: capturedImage).resizable().scaledToFill()
                } else if camera.accessState == .allowed {
                    CameraPreview(session: camera.session)
                } else if camera.accessState == .denied {
                    deniedState
                } else {
                    ProgressView().tint(Theme.white)
                }
            }
            // Chained separately to avoid the "Extra argument" error
            .frame(maxWidth: .infinity)
            .frame(height: 380)
    
            shutter.padding(.bottom, 18)
        }
        .background(Theme.darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Theme.black.opacity(0.08), radius: 14, x: 0, y: 6)
    }

    private var deniedState: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.fill")
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.white.opacity(0.85))
            Text("Camera access is denied")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.white)
            Text("Enable camera access in Settings to scan text.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
                                                                                                                
    // MARK: - Text Area
                                                                                                                
    private var textArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Captured Text")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSecondary)

            ScrollView {
                Text(displayText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(ocr.scannedText.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
            .frame(height: 120)
            .background(Theme.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
        }
    }

    private var displayText: String {
        if ocr.isProcessing { return "Reading text…" }
        if ocr.scannedText.isEmpty { return "Tap the shutter to capture text." }
        return ocr.scannedText
    }

    // MARK: - Buttons

    private var buttonRow: some View {
        HStack(spacing: 12) {
            Button("Clear", action: clear)
                .buttonStyle(SecondaryButtonStyle(color: Theme.red))
                .disabled(capturedImage == nil && ocr.scannedText.isEmpty)

            Spacer()

            Button(action: handleGenerate) {
                HStack(spacing: 6) {
                    Text("Make the Mindmap")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.red, isFullWidth: false))
            .disabled(generateDisabled)
        }
    }

    private var generateDisabled: Bool {
        ocr.scannedText.trimmingCharacters(in: .whitespacesAndNewlines).count < 10
    }

    // MARK: - Shutter

    private var shutter: some View {
        Button(action: handleShutter) {
            ZStack {
                Circle().stroke(Theme.white, lineWidth: 4).frame(width: 78, height: 78)
                Circle().fill(Theme.white).frame(width: 62, height: 62).shadow(color: Theme.black.opacity(0.25), radius: 6, y: 3)
                if ocr.isProcessing { ProgressView().tint(Theme.red) }
            }
        }
        .disabled(camera.accessState != .allowed || ocr.isProcessing)
        .opacity(camera.accessState != .allowed ? 0.55 : 1)
    }
                                                                                                                    
    // MARK: - Actions

    private func handleShutter() {
        Task {
            guard let image = await camera.capturePhoto() else { return }
            capturedImage = image
            _ = await ocr.processScannedPages([image])
        }
    }

    private func clear() {
        capturedImage = nil
        ocr.scannedText = ""
        ocr.errorMessage = nil
    }

    private func handleGenerate() {
        let text = ocr.scannedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onTextCaptured(text)
    }
}

#Preview {
    NavigationStack {
        CameraView { text in
            print("Preview captured text: \(text)")
        }
    }
}
