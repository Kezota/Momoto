//
//  MindmapLayoutEngineTests.swift
//  MomotoTests
//
//  Created by Kezia Meilany Tandapai on 30/09/26.
//

import Testing
import Foundation
@testable import Momoto

@Suite @MainActor
struct MindmapLayoutEngineTests {

    @Test func childrenSitRightOfParentAndNeverOverlap() async throws {
        let a = MindMapNode(title: "First child", isExpanded: true)
        let b = MindMapNode(title: "Second child with a much longer title that wraps", isExpanded: true)
        let c = MindMapNode(title: "Third child", isExpanded: true)
        let root = MindMapNode(title: "Root", children: [a, b, c], isExpanded: true)

        let result = MindmapLayoutEngine.layout(root: root)
        let pos = result.layout.positions

        // Every node got a position.
        #expect(pos.count == 4)

        // Children are exactly one column to the right of the root.
        let rootX = pos[root.id]!.origin.x
        for child in [a, b, c] {
            #expect(pos[child.id]!.origin.x > rootX)
            #expect(pos[child.id]!.depth == 1)
        }

        // Siblings are stacked top to bottom without overlapping,
        // even when one of them wraps to several lines.
        let frames = [a, b, c].map { pos[$0.id]! }
        for (upper, lower) in zip(frames, frames.dropFirst()) {
            let upperBottom = upper.origin.y + upper.height
            #expect(lower.origin.y >= upperBottom)
        }

        // The canvas is big enough to contain everything.
        for p in pos.values {
            #expect(p.origin.y + p.height <= result.contentSize.height)
            #expect(p.origin.x + MindmapNodeView.width <= result.contentSize.width)
        }
    }
    
    @Test func deliberatelyFails() {
        let node = MindMapNode(title: "Root", isExpanded: true)
        let result = MindmapLayoutEngine.layout(root: node)

        // Wrong on purpose: a single root should produce exactly 1 position, not 2.
        #expect(result.layout.positions.count == 2, "Expected a lone root to yield one position")
    }

}
