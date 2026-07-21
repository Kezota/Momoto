//
//  IconPickerView.swift
//  Momoto
//

import SwiftUI

struct IconPickerView: View {
    let currentSymbol: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(MindmapIconLibrary.all, id: \.self) { symbol in
                        Button {
                            onSelect(symbol)
                            dismiss()
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(symbol == currentSymbol ? Theme.purple : Theme.textPrimary)
                                .frame(width: 52, height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(symbol == currentSymbol ? Theme.accentSoft : Theme.background)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(symbol == currentSymbol ? Theme.purple : Theme.stroke, lineWidth: symbol == currentSymbol ? 2 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
