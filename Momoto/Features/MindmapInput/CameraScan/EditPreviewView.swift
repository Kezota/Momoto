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
            Button {
                viewModel.retake()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            .padding(.top, 16)
            
            Text("Edit Preview")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            
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
                Button("Re-scan") {
                    viewModel.retake()
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.purple))
                
                Button(action: {
                    viewModel.handleGenerate(onTextCaptured: onTextCaptured)
                }) {
                    Text("Generate")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
                .disabled(viewModel.generateDisabled)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
    }
}
