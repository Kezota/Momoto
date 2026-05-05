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

    init() {
        mindMap = MindmapViewModel.makeDummyMindMap()
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

    // MARK: - Dummy Data

    static func makeDummyMindMap() -> MindMap {
        let root = MindMapNode(
            title: "Fotosintesis",
            summary: "Proses tumbuhan mengubah cahaya matahari menjadi energi kimia.",
            children: [
                MindMapNode(
                    title: "Bahan Baku",
                    summary: "Zat-zat yang dibutuhkan agar fotosintesis bisa berlangsung.",
                    children: [
                        MindMapNode(title: "Air (H₂O)", summary: "Diserap oleh akar dari dalam tanah."),
                        MindMapNode(title: "CO₂", summary: "Diserap dari udara melalui stomata daun."),
                        MindMapNode(title: "Cahaya Matahari", summary: "Sumber energi utama proses ini.")
                    ],
                    isExpanded: true
                ),
                MindMapNode(
                    title: "Hasil",
                    summary: "Produk yang dihasilkan dari proses fotosintesis.",
                    children: [
                        MindMapNode(title: "Glukosa", summary: "Energi yang disimpan oleh tumbuhan."),
                        MindMapNode(title: "Oksigen (O₂)", summary: "Dilepaskan ke udara sebagai produk sampingan.")
                    ],
                    isExpanded: true
                ),
                MindMapNode(
                    title: "Tempat",
                    summary: "Organel sel tempat fotosintesis berlangsung.",
                    children: [
                        MindMapNode(title: "Kloroplas", summary: "Organel yang mengandung klorofil."),
                        MindMapNode(title: "Klorofil", summary: "Pigmen hijau yang menyerap cahaya.")
                    ],
                    isExpanded: false
                )
            ],
            isExpanded: true
        )

        return MindMap(
            id: UUID(),
            title: "Fotosintesis",
            root: root,
            rawText: "Fotosintesis adalah proses tumbuhan mengubah cahaya matahari...",
            createdAt: Date(), source: "Dummy Data"
        )
    }
}
