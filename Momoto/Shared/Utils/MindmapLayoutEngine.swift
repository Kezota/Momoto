//
//  MindmapLayoutEngine.swift
//  Momoto
//

import SwiftUI

/// The single source of truth for mindmap geometry.
///
/// Extracted from `MindmapViewModel` so that anything needing to *draw* a mindmap — the live
/// canvas, the share/export image, and the small card thumbnails — derives positions from the
/// same math. Previously the thumbnails approximated the tree with their own sketch layout,
/// which meant a preview could disagree with the mindmap it represented.
enum MindmapLayoutEngine {

    static let columnSpacing: CGFloat = 60
    static let rowSpacing: CGFloat = 20

    struct Result {
        let layout: LayoutResult
        let contentSize: CGSize
    }

    static func layout(root: MindMapNode) -> Result {
        let layout = build(node: root, depth: 0, startY: 0)
        return Result(layout: layout, contentSize: canvasSize(positions: layout.positions))
    }

    private static func build(
        node: MindMapNode,
        depth: Int,
        startY: CGFloat,
        parentID: UUID? = nil,
        branchIndex: Int? = nil
    ) -> LayoutResult {
        var positions: [UUID: NodePosition] = [:]
        let x = CGFloat(depth) * (MindmapNodeView.width + columnSpacing)
        let ownHeight = nodeHeight(title: node.title, depth: depth)

        if node.isExpanded && !node.children.isEmpty {
            var childY = startY

            for (index, child) in node.children.enumerated() {
                // Direct children of the root each start a new branch; deeper descendants inherit it.
                let childBranchIndex = depth == 0 ? index : branchIndex
                let result = build(
                    node: child,
                    depth: depth + 1,
                    startY: childY,
                    parentID: node.id,
                    branchIndex: childBranchIndex
                )
                positions.merge(result.positions) { _, new in new }
                childY += result.totalHeight + rowSpacing
            }

            // A node's own (possibly tall, wrapped) title can exceed its children's combined height.
            let subtreeHeight = max(ownHeight, childY - startY - rowSpacing)
            let centreY = startY + subtreeHeight / 2 - ownHeight / 2

            positions[node.id] = NodePosition(
                id: node.id,
                node: node,
                depth: depth,
                origin: CGPoint(x: x, y: centreY),
                parentID: parentID,
                branchIndex: branchIndex,
                height: ownHeight
            )
            return LayoutResult(positions: positions, totalHeight: subtreeHeight)
        } else {
            positions[node.id] = NodePosition(
                id: node.id,
                node: node,
                depth: depth,
                origin: CGPoint(x: x, y: startY),
                parentID: parentID,
                branchIndex: branchIndex,
                height: ownHeight
            )
            return LayoutResult(positions: positions, totalHeight: ownHeight)
        }
    }

    private static func canvasSize(positions: [UUID: NodePosition]) -> CGSize {
        let maxX = positions.values.map { $0.origin.x + MindmapNodeView.width }.max() ?? 0
        let maxY = positions.values.map { $0.origin.y + $0.height }.max() ?? 0
        return CGSize(width: maxX, height: maxY)
    }
}
