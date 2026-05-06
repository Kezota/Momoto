//
//  HistoryViewModel.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var history: [MindMap] = []
    @Published var searchText: String = ""
    @Published var isDeleteMode: Bool = false
    @Published var selectedDeleteID: Set<UUID> = []
    
    var filteredHistory: [MindMap] {
        searchText.isEmpty ? history : history.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    func load() {
        history = HistoryService.shared.load()
    }
    
    func toggleDeleteMode() {
        isDeleteMode.toggle()
        if !isDeleteMode { selectedDeleteID.removeAll() }
    }
    
    func deleteSelected() {
        selectedDeleteID.forEach { HistoryService.shared.delete(id: $0) }
        selectedDeleteID.removeAll()
        isDeleteMode = false
        load()
    }
    
    func handleTap(on entry: MindMap, tapAction: (MindMap) -> Void) {
        if isDeleteMode {
            if !selectedDeleteID.insert(entry.id).inserted { 
                selectedDeleteID.remove(entry.id) 
            }
        } else {
            tapAction(entry)
        }
    }
    
    func handleDelete(for entry: MindMap) {
        HistoryService.shared.delete(id: entry.id)
        load()
    }
}
