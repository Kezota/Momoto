//
//  CameraView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI
import UIKit

enum AppTheme {
      static let background    = Color(red: 0.97, green: 0.96, blue: 0.93)   // warm off-white
      static let card          = Color.white
      static let darkCard      = Color(red: 0.13, green: 0.13, blue: 0.18)   // near-black for camera frame
      static let accent        = Color(red: 0.49, green: 0.36, blue: 0.94)   // soft purple
      static let accentSoft    = Color(red: 0.93, green: 0.90, blue: 1.00)   // pale lavender
      static let textPrimary   = Color(red: 0.13, green: 0.13, blue: 0.18)
      static let textSecondary = Color(red: 0.45, green: 0.47, blue: 0.55)
      static let border        = Color(red: 0.91, green: 0.89, blue: 0.85)   // soft cream border
  }

struct CameraView: View {
    
    let onTextCaptured: (String) -> Void

    @StateObject private var camera = CameraSessionService()
    @StateObject private var ocr    = OCRViewModel()
    @State private var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
                                                                                                                         
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                cameraArea
                textArea
                Spacer(minLength: 0)
                buttonRow
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .navigationTitle("Scan with Camera")
        .padding(.top, 50)
        .navigationBarTitleDisplayMode(.large)
        .onAppear  { camera.bootstrap() }
        .onDisappear { camera.stop() }
        .alert(
            "Couldn't read the text",
            isPresented: Binding(
                get: { ocr.errorMessage != nil },
                set: { if !$0 { ocr.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(ocr.errorMessage ?? "") }
        )
    }

    // MARK: - Camera area

    @ViewBuilder
      private var cameraArea: some View {
          ZStack(alignment: .bottom) {
              Group {
                  if let capturedImage {
                      Image(uiImage: capturedImage)
                          .resizable()
                          .scaledToFill()
                  } else if camera.accessState == .allowed {
                      CameraPreview(session: camera.session)
                  } else if camera.accessState == .denied {
                      deniedState
                  } else {
                      ProgressView().tint(.white)
                  }
              }
              .frame(maxWidth: .infinity)
              .frame(height: 380)
      
              shutter
                  .padding(.bottom, 18)
          }
          .background(AppTheme.darkCard)
          .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
          .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
      } 

    private var deniedState: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text("Camera access is denied")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
            Text("Enable camera access in Settings to scan text.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
                                                                                                                         
    // MARK: - Text area
                                                                                                                         
    private var textArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Captured Text")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            ScrollView {
                Text(displayText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(ocr.scannedText.isEmpty
                                     ? AppTheme.textSecondary
                                     : AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
            .frame(height: 120)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
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
            Button(action: clear) {
                Text("Clear")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppTheme.accentSoft))
            }
            .disabled(capturedImage == nil && ocr.scannedText.isEmpty)
            .opacity(capturedImage == nil && ocr.scannedText.isEmpty ? 0.5 : 1)

            Spacer()

            Button(action: handleGenerate) {
                HStack(spacing: 6) {
                    Text("Make the Mindmap")
                    Image(systemName: "arrow.right")
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Capsule().fill(AppTheme.accent))
                .shadow(color: AppTheme.accent.opacity(0.35), radius: 10, y: 4)
            }
            .disabled(generateDisabled)
            .opacity(generateDisabled ? 0.55 : 1)
        }
    }

    private var generateDisabled: Bool {
        ocr.scannedText.trimmingCharacters(in: .whitespacesAndNewlines).count < 10
    }

    // MARK: - Shutter

    private var shutter: some View {
          Button(action: handleShutter) {
              ZStack {
                  Circle()
                      .stroke(Color.white, lineWidth: 4)         // was AppTheme.textSecondary
                      .frame(width: 78, height: 78)
                  Circle()
                      .fill(Color.white)
                      .frame(width: 62, height: 62)
                      .shadow(color: Color.black.opacity(0.25), radius: 6, y: 3)
                  if ocr.isProcessing {
                      ProgressView().tint(AppTheme.accent)
                  }
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
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CameraView { text in
            print("Preview captured text: \(text)")
        }
    }
}
