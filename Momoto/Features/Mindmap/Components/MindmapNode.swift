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
    let isEditing: Bool
    let onCommit: (String) -> Void
    var focusedNodeID: FocusState<UUID?>.Binding
    
    @State private var editText: String = ""
    
    static let width: CGFloat = 160
    static let height: CGFloat = 58
    
    var body: some View {
        HStack(spacing: 8) {
            if !node.symbol.isEmpty {
                Image(systemName: node.symbol)
                    .font(.system(depth == 0 ? .headline : .subheadline, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            
            if isEditing {
                TextField("", text: $editText, onCommit: {
                    onCommit(editText)
                })
                .focused(focusedNodeID, equals: node.id)
                .font(.system(depth == 0 ? .headline : .subheadline, design: .rounded))
                .fontWeight(depth == 0 ? .bold : .semibold)
                .foregroundStyle(Theme.textPrimary)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
                .onChange(of: focusedNodeID.wrappedValue) { _, newValue in
                    if newValue != node.id {
                        onCommit(editText)
                    }
                }
            } else {
                Text(node.title)
                    .font(.system(depth == 0 ? .headline : .subheadline, design: .rounded))
                    .fontWeight(depth == 0 ? .bold : .semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Theme.textPrimary)
            }
            
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
        .onAppear {
            if isEditing {
                editText = node.title
            }
        }
        .onChange(of: isEditing) { _, newValue in
            if newValue {
                editText = node.title
            }
        }
        .onDisappear()
    }
}
