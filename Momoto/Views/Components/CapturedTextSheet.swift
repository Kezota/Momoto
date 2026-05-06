//
//  CapturedTextSheet.swift
//  MomotoMindmap
//

import SwiftUI

struct CapturedTextSheet: View {
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
                    
                    TextEditor(text: $viewModel.ocr.scannedText)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(16)
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
