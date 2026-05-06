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
}

struct LayoutResult {
    var positions: [UUID: NodePosition]
    var totalHeight: CGFloat
}
