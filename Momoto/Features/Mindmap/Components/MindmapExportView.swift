//
//  MindmapExportView.swift
//  Momoto
//

import SwiftUI

/// Static, non-interactive render of the full mindmap tree (current fold/unfold state,
/// unaffected by canvas pan/zoom) — used to snapshot an image for sharing/saving.
struct MindmapExportView: View {
    let positions: [UUID: NodePosition]
    let contentSize: CGSize

    private let padding: CGFloat = 32

    var body: some View {
        ZStack(alignment: .topLeading) {
            MindmapLineLayer(positions: positions, size: contentSize)

            ForEach(Array(positions.values), id: \.id) { pos in
                MindmapNodeView(
                    node: pos.node,
                    depth: pos.depth,
                    isSelected: false,
                    isEditing: false,
                    branchIndex: pos.branchIndex,
                    height: pos.height,
                    onCommit: { _ in }
                )
                .offset(x: pos.origin.x, y: pos.origin.y)
            }
        }
        .frame(width: contentSize.width, height: contentSize.height)
        .padding(padding)
        .background(Theme.white)
    }
}
