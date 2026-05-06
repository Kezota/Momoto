//
//  NodePopup.swift
//  Momoto
//
//  Created by Kezia Meilany Tandapai on 07/05/26.
//


import SwiftUI

struct NodePopup: View {
    let node: MindMapNode
    let onDismiss: () -> Void
    
    var body: some View {
        Theme.black.opacity(0.15)
            .ignoresSafeArea()
            .onTapGesture { onDismiss() }
            .overlay {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(node.title)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.system(.title3, design: .rounded))
                        }
                    }
                    
                    Divider()
                    
                    Text((node.summary?.isEmpty == false) ? node.summary! : "Tidak ada ringkasan.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: 300)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.white)
                        .shadow(color: Theme.black.opacity(0.15), radius: 12, x: 0, y: 4)
                )
            }
    }
}
