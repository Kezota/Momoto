//
//  MindMapNode.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import Foundation

struct MindMapNode: Identifiable, Codable, Hashable {
    let id: UUID;
    var title: String
    var symbol: String
    var summary: String?
    var children: [MindMapNode]
    var isExpanded: Bool
    
    init(id: UUID = UUID(), title: String = "", symbol: String = "", summary: String = "", children: [MindMapNode] = [], isExpanded: Bool = false) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.summary = summary
        self.children = children
        self.isExpanded = isExpanded
    }

    /// Deep copy with fresh identifiers throughout, so a duplicated tree can't share node IDs
    /// with the original (which would make selection and editing act on both).
    func regeneratingIDs() -> MindMapNode {
        MindMapNode(
            id: UUID(),
            title: title,
            symbol: symbol,
            summary: summary ?? "",
            children: children.map { $0.regeneratingIDs() },
            isExpanded: isExpanded
        )
    }
}

// Placeholder for AI, exclude UUID & isExpanded from MindMapNode
struct NodeDTO: Codable {
    let title: String
    let summary: String?
    let symbol: String?
    let children: [NodeDTO]?
}

struct NodePosition {
    let id: UUID
    let node: MindMapNode
    let depth: Int
    let origin: CGPoint
    let parentID: UUID?
    /// Index of the top-level branch (direct child of root) this node descends from. Nil for the root itself.
    let branchIndex: Int?
    /// Rendered height of this node — varies with title length instead of a fixed constant.
    let height: CGFloat
}

struct LayoutResult {
    var positions: [UUID: NodePosition]
    var totalHeight: CGFloat
}
