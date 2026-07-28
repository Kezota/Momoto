//
//  MindmapExportView.swift
//  Momoto
//

import SwiftUI

/// Static, non-interactive render of a mindmap tree at its natural size — no pan/zoom, no
/// gestures, no chrome. Shared by the export/share snapshot and the card thumbnails so every
/// non-interactive depiction of a mindmap is pixel-identical to the live canvas.
struct MindmapStaticCanvas: View {
    let positions: [UUID: NodePosition]
    let contentSize: CGSize

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
    }
}

/// Full-tree render used to snapshot an image for sharing/saving.
struct MindmapExportView: View {
    let positions: [UUID: NodePosition]
    let contentSize: CGSize

    private let padding: CGFloat = 32

    var body: some View {
        MindmapStaticCanvas(positions: positions, contentSize: contentSize)
            .padding(padding)
            .background(Theme.white)
    }
}
