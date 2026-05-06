//
//  MindmapViewModel.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI
import Combine

final class MindmapViewModel: ObservableObject {
    
    @Published var mindMap: MindMap
    @Published var selectedNodeID: UUID? = nil
    @Published var cachedLayout: LayoutResult = LayoutResult(positions: [:], totalHeight: 0)
    @Published var contentSize: CGSize = .zero
    
    private let columnSpacing: CGFloat = 60
    private let rowSpacing: CGFloat = 20
    
    init(mindMap: MindMap) {
        self.mindMap = mindMap
        recalculateLayout()
    }
    
    // MARK: - Expand / Collapse
    
    func toggleExpand(nodeID: UUID) {
        mindMap.root = toggleNode(mindMap.root, targetID: nodeID)
        recalculateLayout()
    }
    
    // Expand atau collapse semua node sekaligus
    func expandAll(_ expanded: Bool) {
        mindMap.root = setExpanded(mindMap.root, value: expanded)
        recalculateLayout()
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
    
    // MARK: - Layout Engine
    
    func recalculateLayout() {
        cachedLayout = buildLayout(node: mindMap.root, depth: 0, startY: 0)
        contentSize = calculateCanvasSize(positions: cachedLayout.positions)
    }
    
    private func buildLayout(node: MindMapNode, depth: Int, startY: CGFloat, parentID: UUID? = nil) -> LayoutResult {
        var positions: [UUID: NodePosition] = [:]
        let x = CGFloat(depth) * (MindmapNodeView.width + columnSpacing)
        
        if node.isExpanded && !node.children.isEmpty {
            var childY = startY
            
            for child in node.children {
                let result = buildLayout(node: child, depth: depth + 1, startY: childY, parentID: node.id)
                positions.merge(result.positions) { _, new in new }
                childY += result.totalHeight + rowSpacing
            }
            
            let subtreeHeight = childY - startY - rowSpacing
            let centreY = startY + subtreeHeight / 2 - MindmapNodeView.height / 2
            
            positions[node.id] = NodePosition(id: node.id, node: node, depth: depth, origin: CGPoint(x: x, y: centreY), parentID: parentID)
            return LayoutResult(positions: positions, totalHeight: subtreeHeight)
        } else {
            positions[node.id] = NodePosition(id: node.id, node: node, depth: depth, origin: CGPoint(x: x, y: startY), parentID: parentID)
            return LayoutResult(positions: positions, totalHeight: MindmapNodeView.height)
        }
    }
    
    private func calculateCanvasSize(positions: [UUID: NodePosition]) -> CGSize {
        let maxX = positions.values.map { $0.origin.x + MindmapNodeView.width }.max() ?? 0
        let maxY = positions.values.map { $0.origin.y + MindmapNodeView.height }.max() ?? 0
        return CGSize(width: maxX, height: maxY)
    }
    
}

