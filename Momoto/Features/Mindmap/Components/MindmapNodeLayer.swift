//
//  MindmapNodeLayer.swift
//  MomotoMindmap
//

import SwiftUI

struct MindmapNodeLayer: View {
    @ObservedObject var viewModel: MindmapViewModel
    let onLongPress: (MindMapNode) -> Void
    
    @FocusState private var focusedNodeID: UUID?
    
    var body: some View {
        ForEach(Array(viewModel.cachedLayout.positions.values), id: \.id) { pos in
            MindmapNodeView(
                node: pos.node,
                depth: pos.depth,
                isSelected: viewModel.selectedNodeID == pos.node.id,
                isEditing: viewModel.editingNodeID == pos.node.id,
                isGenerating: viewModel.generatingNodeID == pos.node.id,
                onCommit: { newTitle in
                    viewModel.renameNode(nodeID: pos.node.id, newTitle: newTitle)
                    viewModel.editingNodeID = nil
                },
                focusedNodeID: $focusedNodeID
            )
            .offset(x: pos.origin.x, y: pos.origin.y)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if viewModel.isEditModeActive {
                        viewModel.selectedNodeID = pos.node.id
                        viewModel.showFloatingMenuForNodeID = nil
                    } else {
                        viewModel.selectNode(nodeID: pos.node.id)
                            if !pos.node.children.isEmpty {
                                viewModel.toggleExpand(nodeID: pos.node.id)
                            }
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if viewModel.isEditModeActive {
                        viewModel.selectedNodeID = pos.node.id
                        viewModel.showFloatingMenuForNodeID = pos.node.id
                    } else {
                        onLongPress(pos.node)
                    }
                }
            }
        }
        .onChange(of: viewModel.editingNodeID) { _, newValue in
            focusedNodeID = newValue
        }
    }
}
