//
//  MindmapNode.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI

// MindmapNode is the visual "bubble" that represents one node in the mindmap.
// It shows the title, a chevron if there are children, and highlights when selected.
struct MindmapNodeView: View {
    let node: MindMapNode
    let depth: Int
    let isSelected: Bool

    // Fixed size so the layout engine can calculate positions consistently
    static let width: CGFloat = 160
    static let height: CGFloat = 58

    var body: some View {
        HStack(spacing: 8) {
            Text(node.title)
                .font(.system(size: depth == 0 ? 16 : 14,
                              weight: depth == 0 ? .bold : .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            // Show chevron only when the node has children
            if !node.children.isEmpty {
                Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: Self.width, height: Self.height)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorForDepth(depth))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isSelected ? Color.accentColor : Color.black.opacity(0.08),
                    lineWidth: isSelected ? 2.5 : 1
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    // Each depth level gets a soft pastel colour so the tree is easy to read
    private func colorForDepth(_ depth: Int) -> Color {
        switch depth {
        case 0:  return Color(red: 0.90, green: 0.95, blue: 1.00) // light blue  – root
        case 1:  return Color(red: 0.95, green: 0.99, blue: 0.92) // light green – level 1
        case 2:  return Color(red: 1.00, green: 0.97, blue: 0.90) // light peach – level 2
        default: return Color(red: 0.99, green: 0.93, blue: 0.94) // light pink  – deeper
        }
    }
}
