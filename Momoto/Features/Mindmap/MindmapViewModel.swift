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
    
    @Published var isEditModeActive: Bool = false
    @Published var editingNodeID: UUID? = nil
    @Published var showFloatingMenuForNodeID: UUID? = nil
    @Published var generatingNodeID: UUID? = nil
    @Published var iconPickerNodeID: UUID? = nil

    static var copiedNode: MindMapNode? = nil

    private let columnSpacing: CGFloat = 60
    private let rowSpacing: CGFloat = 20
    private let chatbotService = ChatbotService()
    
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
    
    // MARK: - Node Operations
    
    @discardableResult
    func addChild(to parentID: UUID, title: String = "New Node", symbol: String = "circle") -> UUID {
        let newNode = MindMapNode(id: UUID(), title: title, symbol: symbol, summary: "", children: [], isExpanded: true)
        
        func insertChild(in node: MindMapNode) -> MindMapNode {
            var copy = node
            if copy.id == parentID {
                copy.isExpanded = true
                copy.children.append(newNode)
                return copy
            }
            copy.children = copy.children.map { insertChild(in: $0) }
            return copy
        }
        
        mindMap.root = insertChild(in: mindMap.root)
        recalculateLayout()
        persistChange()
        return newNode.id
    }
    
    func addSibling(to targetID: UUID, title: String = "New Node") -> UUID? {
        let newNode = MindMapNode(id: UUID(), title: title, symbol: "circle", summary: "", children: [], isExpanded: true)
        return insertSibling(newNode, after: targetID)
    }

    @discardableResult
    func duplicateNode(_ node: MindMapNode) -> UUID? {
        let duplicate = recreateUUIDs(for: node)
        return insertSibling(duplicate, after: node.id)
    }

    @discardableResult
    private func insertSibling(_ newNode: MindMapNode, after targetID: UUID) -> UUID? {
        // Root cannot have siblings
        if mindMap.root.id == targetID {
            return nil
        }

        func insert(in node: MindMapNode) -> (node: MindMapNode, found: Bool) {
            var copy = node

            if let index = copy.children.firstIndex(where: { $0.id == targetID }) {
                copy.children.insert(newNode, at: index + 1)
                return (copy, true)
            }

            var foundAny = false
            copy.children = copy.children.map { child in
                let result = insert(in: child)
                if result.found {
                    foundAny = true
                }
                return result.node
            }

            return (copy, foundAny)
        }

        let result = insert(in: mindMap.root)
        if result.found {
            mindMap.root = result.node
            recalculateLayout()
            persistChange()
            return newNode.id
        }
        return nil
    }
    
    func deleteNode(nodeID: UUID) {
        if mindMap.root.id == nodeID {
            mindMap.root.title = "Root"
            mindMap.root.children = []
            selectedNodeID = nil
            recalculateLayout()
            persistChange()
            return
        }
        
        func removeNode(from node: MindMapNode) -> MindMapNode {
            var copy = node
            copy.children = copy.children.filter { $0.id != nodeID }
            copy.children = copy.children.map { removeNode(from: $0) }
            return copy
        }
        
        mindMap.root = removeNode(from: mindMap.root)
        if selectedNodeID == nodeID {
            selectedNodeID = nil
        }
        recalculateLayout()
        persistChange()
    }
    
    func renameNode(nodeID: UUID, newTitle: String) {
        func updateTitle(in node: MindMapNode) -> MindMapNode {
            var copy = node
            if copy.id == nodeID {
                copy.title = newTitle
                return copy
            }
            copy.children = copy.children.map { updateTitle(in: $0) }
            return copy
        }
        
        mindMap.root = updateTitle(in: mindMap.root)
        if mindMap.root.id == nodeID {
            mindMap.title = newTitle
        }
        recalculateLayout()
        persistChange()
    }
    
    func setSymbol(nodeID: UUID, symbol: String) {
        func updateSymbol(in node: MindMapNode) -> MindMapNode {
            var copy = node
            if copy.id == nodeID {
                copy.symbol = symbol
                return copy
            }
            copy.children = copy.children.map { updateSymbol(in: $0) }
            return copy
        }

        mindMap.root = updateSymbol(in: mindMap.root)
        recalculateLayout()
        persistChange()
    }

    func findNode(id: UUID) -> MindMapNode? {
        func search(_ node: MindMapNode) -> MindMapNode? {
            if node.id == id { return node }
            for child in node.children {
                if let found = search(child) { return found }
            }
            return nil
        }
        return search(mindMap.root)
    }

    func copyNode(_ node: MindMapNode) {
        UIPasteboard.general.string = node.title
        Self.copiedNode = node
    }

    func cutNode(_ node: MindMapNode) {
        copyNode(node)
        deleteNode(nodeID: node.id)
    }
    
    func pasteNode(to parentID: UUID) {
        if let copied = Self.copiedNode {
            let newNode = recreateUUIDs(for: copied)
            
            func insertChild(in node: MindMapNode) -> MindMapNode {
                var copy = node
                if copy.id == parentID {
                    copy.isExpanded = true
                    copy.children.append(newNode)
                    return copy
                }
                copy.children = copy.children.map { insertChild(in: $0) }
                return copy
            }
            
            mindMap.root = insertChild(in: mindMap.root)
            recalculateLayout()
            persistChange()
        } else if let text = UIPasteboard.general.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _ = addChild(to: parentID, title: text)
        }
    }
    
    private func recreateUUIDs(for node: MindMapNode) -> MindMapNode {
        MindMapNode(
            id: UUID(),
            title: node.title,
            symbol: node.symbol,
            summary: node.summary ?? "",
            children: node.children.map { recreateUUIDs(for: $0) },
            isExpanded: node.isExpanded
        )
    }
    
    private func persistChange() {
        mindMap.rawText = outlineText(from: mindMap.root)
        HistoryService.shared.update(mindmap: mindMap)
    }
    
    // MARK: - Chatbot context
    
    var modelContext: ModelContext {
        ModelContext(
            rawText: mindMap.rawText,
            hierarchyOutline: outlineText(from: mindMap.root),
            selectedNodeTitle: selectedNodeID.flatMap { findTitle(in: mindMap.root, id: $0) }
        )
    }
    
    func growIdeas(for node: MindMapNode) {
        guard generatingNodeID == nil else { return }
        let context = modelContext
        generatingNodeID = node.id
        Task { @MainActor in
            let ideas = await chatbotService.growIdeas(for: node.title, context: context)
            for idea in ideas {
                addChild(to: node.id, title: idea.title, symbol: idea.icon)
            }
            generatingNodeID = nil
        }
    }

    func workBreakdown(for node: MindMapNode) {
        guard generatingNodeID == nil else { return }
        let context = modelContext
        generatingNodeID = node.id
        Task { @MainActor in
            let tasks = await chatbotService.workBreakdown(for: node.title, context: context)
            for task in tasks {
                addChild(to: node.id, title: task.title, symbol: task.icon)
            }
            generatingNodeID = nil
        }
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
    
    private func buildLayout(node: MindMapNode, depth: Int, startY: CGFloat, parentID: UUID? = nil, branchIndex: Int? = nil) -> LayoutResult {
        var positions: [UUID: NodePosition] = [:]
        let x = CGFloat(depth) * (MindmapNodeView.width + columnSpacing)
        let ownHeight = nodeHeight(title: node.title, depth: depth)

        if node.isExpanded && !node.children.isEmpty {
            var childY = startY

            for (index, child) in node.children.enumerated() {
                // Direct children of the root each start a new branch; deeper descendants inherit it.
                let childBranchIndex = depth == 0 ? index : branchIndex
                let result = buildLayout(node: child, depth: depth + 1, startY: childY, parentID: node.id, branchIndex: childBranchIndex)
                positions.merge(result.positions) { _, new in new }
                childY += result.totalHeight + rowSpacing
            }

            // A node's own (possibly tall, wrapped) title can exceed its children's combined height.
            let subtreeHeight = max(ownHeight, childY - startY - rowSpacing)
            let centreY = startY + subtreeHeight / 2 - ownHeight / 2

            positions[node.id] = NodePosition(id: node.id, node: node, depth: depth, origin: CGPoint(x: x, y: centreY), parentID: parentID, branchIndex: branchIndex, height: ownHeight)
            return LayoutResult(positions: positions, totalHeight: subtreeHeight)
        } else {
            positions[node.id] = NodePosition(id: node.id, node: node, depth: depth, origin: CGPoint(x: x, y: startY), parentID: parentID, branchIndex: branchIndex, height: ownHeight)
            return LayoutResult(positions: positions, totalHeight: ownHeight)
        }
    }

    private func calculateCanvasSize(positions: [UUID: NodePosition]) -> CGSize {
        let maxX = positions.values.map { $0.origin.x + MindmapNodeView.width }.max() ?? 0
        let maxY = positions.values.map { $0.origin.y + $0.height }.max() ?? 0
        return CGSize(width: maxX, height: maxY)
    }
    
}

