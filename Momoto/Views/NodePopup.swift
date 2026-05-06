//
//  NodePopup.swift
//  Momoto
//
//  Created by Kezia Meilany Tandapai on 06/05/26.
//


import SwiftUI

// MARK: - Popup
struct NodePopup: View {
    let node: MindMapNode
    let onDismiss: () -> Void

    var body: some View {
        Theme.black.opacity(0.15)
            .ignoresSafeArea()
            .onTapGesture { onDismiss() }
            .overlay {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        Text(node.title)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.system(.title2, design: .rounded))
                        }
                    }

                    Divider()

                    Text((node.summary?.isEmpty == false) ? node.summary! : "No summary available.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.textPrimary.opacity(0.85))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
                .frame(maxWidth: 320)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.background)
                        .shadow(color: Theme.black.opacity(0.15), radius: 16, x: 0, y: 8)
                )
            }
    }
}
