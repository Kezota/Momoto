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
            .background(
                EditMenuBridge(
                    isPresented: viewModel.isEditModeActive && viewModel.showFloatingMenuForNodeID == pos.node.id && viewModel.editingNodeID == nil,
                    actions: [
                        EditMenuAction(title: "Copy") {
                            viewModel.copyNode(pos.node)
                        },
                        EditMenuAction(title: "Paste") {
                            viewModel.pasteNode(to: pos.node.id)
                        },
                        EditMenuAction(title: "Rename") {
                            viewModel.editingNodeID = pos.node.id
                        },
                        EditMenuAction(title: "Delete", isDestructive: true) {
                            viewModel.deleteNode(nodeID: pos.node.id)
                        },
                        EditMenuAction(title: "+ Child") {
                            let newID = viewModel.addChild(to: pos.node.id)
                            viewModel.selectedNodeID = newID
                            viewModel.editingNodeID = newID
                        },
                        EditMenuAction(title: pos.node.id != viewModel.mindMap.root.id ? "+ Sibling" : "", isDestructive: false) {
                            if let newID = viewModel.addSibling(to: pos.node.id) {
                                viewModel.selectedNodeID = newID
                                viewModel.editingNodeID = newID
                            }
                        },
                        EditMenuAction(title: "> Detail") {
                            onLongPress(pos.node)
                        }
                    ].filter { !$0.title.isEmpty },
                    onDismiss: {
                        viewModel.showFloatingMenuForNodeID = nil
                    }
                )
            )
        }
        .onChange(of: viewModel.editingNodeID) { _, newValue in
            focusedNodeID = newValue
        }
    }
}
