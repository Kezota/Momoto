//
//  ExtractedTextSheet.swift
//  Momoto
//
//  Created by Ken on 25/07/26.
//

import SwiftUI

struct ExtractedTextSheet: View {
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                TextEditor(text: $text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .background(Theme.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
            // Title and Done configure the content *inside* the stack — attached to the
            // NavigationStack itself they'd never reach the bar.
            .navigationTitle("Extracted Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ExtractedTextSheet(text: .constant("Some Extracted Text."))
}
