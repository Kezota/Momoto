//
//  EditPreviewView.swift
//  Momoto
//
//  Created by Teresa Tendeas on 02/06/26.
//

import SwiftUI

struct EditPreviewView: View {
    @ObservedObject var viewModel: CameraViewModel
    let onTextCaptured: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Navigation chrome (title + Rescan) is owned by CameraView's toolbar.
            Text("Check the text and fix anything that looks wrong.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            TextEditor(text: $viewModel.ocr.scannedText)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(16)
                .frame(maxHeight: .infinity)
                .background(Theme.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
            
            HStack(spacing: 12) {
                Button("Rescan") {
                    viewModel.retake()
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.purple))

                // Advances to the Personalize step rather than generating straight away.
                Button(action: {
                    viewModel.handleGenerate(onTextCaptured: onTextCaptured)
                }) {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
                .disabled(viewModel.generateDisabled)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
    }
}
