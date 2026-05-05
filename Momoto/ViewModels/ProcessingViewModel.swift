//
//  ProcessingViewModel.swift
//  Momoto
//
//  Created by Teresa Tendeas on 05/05/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ProcessingViewModel: ObservableObject {

    enum State {
        case loading
        case success(MindMap)
        case failure(String)
    }

    @Published var state: State = .loading

    private let service = TextToNodeService()
    
    private let maxCharacters = 4000
    
    func generate(from text: String, source: String) async {
        state = .loading
        let trimmedText = String(text.prefix(maxCharacters))
        do {
            let rootNode = try await service.generateMindMap(from: trimmedText)
            let mindMap = MindMap(
                id: UUID(),
                title: rootNode.title,
                root: rootNode,
                rawText: text,
                createdAt: Date(),
                source: source
            )
            HistoryService.shared.add(mindmap: mindMap)
            state = .success(mindMap)
        } catch {
            state = .failure(error.localizedDescription)
        }
    }
}
