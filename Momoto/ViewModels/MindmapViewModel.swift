//
//  MindmapViewModel.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI
import Combine

class MindmapViewModel: ObservableObject {
    
    @Published var mindMap: MindMap
    @Published var selectedNodeID: UUID? = nil
    
    init(mindMap: MindMap) {
        self.mindMap = mindMap
    }
    
    // MARK: - Expand / Collapse
    
    func toggleExpand(nodeID: UUID) {
        mindMap.root = toggleNode(mindMap.root, targetID: nodeID)
    }
    
    // Expand atau collapse semua node sekaligus
    func expandAll(_ expanded: Bool) {
        mindMap.root = setExpanded(mindMap.root, value: expanded)
    }
    
    private func toggleNode(_ node: MindMapNode, targetID: UUID) -> MindMapNode {
        var copy = node
        if copy.id == targetID {
            copy.isExpanded.toggle()
            return copy
        }
        copy.children = copy.children.map { toggleNode($0, targetID: targetID) }
        return copy
    }
    
    private func setExpanded(_ node: MindMapNode, value: Bool) -> MindMapNode {
        var copy = node
        if !copy.children.isEmpty { copy.isExpanded = value }
        copy.children = copy.children.map { setExpanded($0, value: value) }
        return copy
    }
    
    // MARK: - Select
    
    func selectNode(nodeID: UUID) {
        selectedNodeID = (selectedNodeID == nodeID) ? nil : nodeID
    }
    // MARK: - Chatbot context
    
    var modelContext: ModelContext {
        ModelContext(
            rawText: mindMap.rawText,
            hierarchyOutline: outlineText(from: mindMap.root),
            selectedNodeTitle: selectedNodeID.flatMap { findTitle(in: mindMap.root, id: $0) }
        )
    }
    
    private func outlineText(from node: MindMapNode, depth: Int = 0) -> String {
        let indent = String(repeating: "  ", count: depth)
        let line = "\(indent)- \(node.title)"
        let childLines = node.children.map { outlineText(from: $0, depth: depth + 1) }
        return ([line] + childLines).joined(separator: "\n")
    }
    
    private func findTitle(in node: MindMapNode, id: UUID) -> String? {
        if node.id == id { return node.title }
        for child in node.children {
            if let found = findTitle(in: child, id: id) { return found }
        }
        return nil
    }
    
}
