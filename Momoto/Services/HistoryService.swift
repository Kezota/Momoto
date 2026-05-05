//
//  HistoryService.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import Foundation // needed to access UserDefaults, etc

final class HistoryService {
    
    static let shared = HistoryService() // one shared service object
    private init() {}
    
    private let key = "mindmap_history"
    
    func load() -> [MindMap] {
        guard let data = UserDefaults.standard.data(forKey: key) else { // Check via key
            return []
        }
        
        do {
            return try JSONDecoder().decode([MindMap].self, from: data) // Get data via decoding JSON
        } catch {
            print("Failed to load history:", error)
            return []
        }
    }
    
    private func save(history: [MindMap]) {
        do {
            let data = try JSONEncoder().encode(history) // Save data via encoding JSON
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save history:", error)
        }
    }
    
    func add(mindmap: MindMap) {
        var history = load()
        history.insert(mindmap, at: 0) // Newest first
        save(history: history)
    }
    
    func delete(id: UUID) {
        var history = load()
        history.removeAll { $0.id == id } // $0 is first closure parameter -> each mindmap
        save(history: history)
    }
    
    func delete(ids: Set<UUID>) {
        var history = load()
        history.removeAll { ids.contains($0.id) }
        save(history: history)
    }
    
    func clear() {
        save(history: [])
    }
}
