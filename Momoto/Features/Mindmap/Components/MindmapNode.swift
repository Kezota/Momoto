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
    var isGenerating: Bool = false
    var branchIndex: Int? = nil
    var height: CGFloat = nodeMinHeight
    let onCommit: (String) -> Void
    var focusedNodeID: FocusState<UUID?>.Binding? = nil

    @State private var editText: String = ""

    static let width: CGFloat = 160

    private var textColor: Color { nodeTextColor(depth: depth) }

    var body: some View {
        HStack(spacing: 8) {
            if !node.symbol.isEmpty {
                Image(systemName: node.symbol)
                    .font(.system(depth == 0 ? .headline : .subheadline, design: .rounded))
                    .foregroundStyle(textColor)
            }

            if isEditing {
                Group {
                    if let focusedNodeID {
                        TextField("", text: $editText, onCommit: {
                            onCommit(editText)
                        })
                        .focused(focusedNodeID, equals: node.id)
                    } else {
                        TextField("", text: $editText, onCommit: {
                            onCommit(editText)
                        })
                    }
                }
                .font(.system(depth == 0 ? .headline : .subheadline, design: .rounded))
                .fontWeight(depth == 0 ? .bold : .semibold)
                .foregroundStyle(textColor)
                .tint(textColor)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
            } else {
                Text(node.title)
                    .font(.system(depth == 0 ? .headline : .subheadline, design: .rounded))
                    .fontWeight(depth == 0 ? .bold : .semibold)
                    .lineLimit(4)
                    .minimumScaleFactor(0.9)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(textColor)
            }

            Spacer(minLength: 0)

            if isGenerating {
                ProgressView()
                    .controlSize(.mini)
            } else if !node.children.isEmpty {
                // Show chevron only when the node has children
                Image(systemName: node.isExpanded ? "chevron.left" : "chevron.right")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(textColor.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: Self.width, height: height)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(nodeFillColor(depth: depth, branchIndex: branchIndex))
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
        .onChange(of: isEditing) { wasEditing, newValue in
            if newValue {
                editText = node.title
            } else if wasEditing {
                onCommit(editText)
            }
        }
        .onDisappear()
    }
}
