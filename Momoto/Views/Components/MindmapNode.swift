//
//  MindmapNode.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI

struct MindmapNodeView: View {
    let node: MindMapNode
    let depth: Int
    let isSelected: Bool

    static let width: CGFloat = 160
    static let height: CGFloat = 58

    var body: some View {
        HStack(spacing: 8) {
            if !node.symbol.isEmpty {
                Image(systemName: node.symbol)
                    .font(.system(depth == 0 ? .headline : .subheadline, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            
            Text(node.title)
                .font(.system(depth == 0 ? .headline : .subheadline, design: .rounded))
                .fontWeight(depth == 0 ? .bold : .semibold)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Theme.textPrimary)

            Spacer(minLength: 0)

            // Show chevron only when the node has children
            if !node.children.isEmpty {
                Image(systemName: node.isExpanded ? "chevron.left" : "chevron.right")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
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
                    isSelected ? Theme.purple : Theme.stroke,
                    lineWidth: isSelected ? 2.5 : 1
                )
        )
        .shadow(color: Theme.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // Each depth level gets a soft tint of the brand palette
    private func colorForDepth(_ depth: Int) -> Color {
        switch depth {
        case 0:  return Theme.purple.opacity(0.10)  // root  – soft purple
        case 1:  return Theme.green.opacity(0.10)   // L1    – soft green
        case 2:  return Theme.yellow.opacity(0.10)  // L2    – soft yellow
        default: return Theme.red.opacity(0.08)     // deep  – soft red
        }
    }
}
