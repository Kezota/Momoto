//
//  MindMap.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import Foundation

struct MindMap: Identifiable, Codable, Hashable {
    let id: UUID;
    var title: String;
    var root: MindMapNode;
    var rawText: String;
    var createdAt: Date;
    var source: String;
    var language: MindmapPreferences.Language

    init(id: UUID, title: String, root: MindMapNode, rawText: String, createdAt: Date, source: String, language: MindmapPreferences.Language = .english) {
        self.id = id
        self.title = title
        self.root = root
        self.rawText = rawText
        self.createdAt = createdAt
        self.source = source
        self.language = language
    }

    // Mindmaps saved before `language` existed decode to English instead of
    // failing to load (older history stays intact).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        root = try c.decode(MindMapNode.self, forKey: .root)
        rawText = try c.decode(String.self, forKey: .rawText)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        source = try c.decode(String.self, forKey: .source)
        language = try c.decodeIfPresent(MindmapPreferences.Language.self, forKey: .language) ?? .english
    }
}
