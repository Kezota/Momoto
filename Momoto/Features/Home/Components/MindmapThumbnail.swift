//
//  MindmapThumbnail.swift
//  Momoto
//

import SwiftUI

/// Miniature preview of a real mindmap, for grid/list cards.
///
/// Renders the actual tree through the shared `MindmapLayoutEngine` and `MindmapStaticCanvas`,
/// then scales the whole canvas down to fit the card. That guarantees a thumbnail always agrees
/// with the mindmap it represents — an earlier version drew its own approximate sketch, which
/// could show a completely different shape from the real thing.
struct MindmapThumbnail: View {
    let root: MindMapNode

    /// Layout is pure geometry over an immutable tree, so it is cached per root identity rather
    /// than recomputed on every scroll pass through a `LazyVGrid`/`LazyVStack` cell.
    @State private var cached: MindmapLayoutEngine.Result?

    var body: some View {
        GeometryReader { geo in
            if let cached, cached.contentSize.width > 0, cached.contentSize.height > 0 {
                let scale = min(
                    geo.size.width / cached.contentSize.width,
                    geo.size.height / cached.contentSize.height
                )

                MindmapStaticCanvas(
                    positions: cached.layout.positions,
                    contentSize: cached.contentSize
                )
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
                // The canvas keeps its natural size and is only visually scaled, so clip it to
                // the cell to stop overflow bleeding into neighbouring cards.
                .clipped()
                .allowsHitTesting(false)
            } else {
                Color.clear
            }
        }
        .task(id: root) {
            if cached == nil {
                cached = MindmapLayoutEngine.layout(root: root)
            }
        }
    }
}

#Preview {
    MindmapThumbnail(
        root: MindMapNode(
            title: "Design Process",
            children: [
                MindMapNode(title: "2. Define", children: [
                    MindMapNode(title: "User Needs"),
                    MindMapNode(title: "Insights"),
                    MindMapNode(title: "Problems")
                ], isExpanded: true),
                MindMapNode(title: "3. Ideate", children: [
                    MindMapNode(title: "Brainstorm"),
                    MindMapNode(title: "Ideas"),
                    MindMapNode(title: "Solutions")
                ], isExpanded: true)
            ],
            isExpanded: true
        )
    )
    .frame(width: 180, height: 128)
    .background(Color.white)
}
