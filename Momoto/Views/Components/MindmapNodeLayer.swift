//
//  MindmapNodeLayer.swift
//  MomotoMindmap
//

import SwiftUI

struct MindmapNodeLayer: View {
    @ObservedObject var viewModel: MindmapViewModel
    let onLongPress: (MindMapNode) -> Void
    
    var body: some View {
        ForEach(Array(viewModel.cachedLayout.positions.values), id: \.id) { pos in
            MindmapNodeView(
                node: pos.node,
                depth: pos.depth,
                isSelected: viewModel.selectedNodeID == pos.node.id
            )
            .offset(x: pos.origin.x, y: pos.origin.y)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectNode(nodeID: pos.node.id)
                    if !pos.node.children.isEmpty {
                        viewModel.toggleExpand(nodeID: pos.node.id)
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onLongPress(pos.node)
                }
            }
        }
    }
}
