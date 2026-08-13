//
//  MindmapThumbnail.swift
//  Momoto
//

import SwiftUI

/// Miniature preview of a real mindmap, for grid/list cards.
///
/// Layout comes from the shared `MindmapLayoutEngine`, so a thumbnail always agrees with the
/// real canvas. The result is rendered ONCE into a `UIImage` and memo-cached: showing a live
/// `MindmapStaticCanvas` per card (dozens of node views with shadows, re-created every time a
/// lazy grid cell recycles) is what made the home screen stutter while scrolling.
struct MindmapThumbnail: View {
    let root: MindMapNode

    @State private var image: UIImage?

    /// Session-scoped cache. Keyed by the tree's content hash, so an edited mindmap renders a
    /// fresh thumbnail while unchanged ones are never re-rendered.
    private static let cache = NSCache<NSString, UIImage>()

    /// Rendered at a fixed size and scaled to fit the cell; card cells are all roughly this
    /// aspect, and one shared bitmap size means one cache entry per mindmap, not per cell size.
    private static let renderSize = CGSize(width: 340, height: 240)

    private var cacheKey: NSString {
        "\(root.id.uuidString)-\(root.hashValue)" as NSString
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: cacheKey) {
            if let cached = Self.cache.object(forKey: cacheKey) {
                image = cached
                return
            }
            if let rendered = Self.render(root: root) {
                Self.cache.setObject(rendered, forKey: cacheKey)
                image = rendered
            }
        }
        .allowsHitTesting(false)
    }

    @MainActor
    private static func render(root: MindMapNode) -> UIImage? {
        let result = MindmapLayoutEngine.layout(root: root)
        guard result.contentSize.width > 0, result.contentSize.height > 0 else { return nil }

        let fit = min(
            renderSize.width / result.contentSize.width,
            renderSize.height / result.contentSize.height
        )

        // The canvas keeps its natural layout size; `scaleEffect` only shrinks it visually.
        // The container must pin the child to .topLeading — the same corner the scale anchors
        // on — otherwise the default centering places the scaled content at a negative origin,
        // outside the rendered bitmap, producing a blank image.
        let canvas = MindmapStaticCanvas(
            positions: result.layout.positions,
            contentSize: result.contentSize
        )
        .scaleEffect(fit, anchor: .topLeading)
        .frame(
            width: result.contentSize.width * fit,
            height: result.contentSize.height * fit,
            alignment: .topLeading
        )

        let renderer = ImageRenderer(content: canvas)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
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
