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
    @Published var textIndex: Int = 0

    private let service = TextToNodeService()
    private let maxCharacters = 6000
    private var timerTask: Task<Void, Never>?

    let loadingTexts = [
        "Reading your content",
        "Identifying key concept",
        "Building node hierarchy",
        "Finalising Mindmap"
    ]

    var currentLoadingText: String {
        guard textIndex < loadingTexts.count else { return "" }
        return loadingTexts[textIndex]
    }

    private func startLoadingAnimation() {
        textIndex = 0
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { break }
                if textIndex < loadingTexts.count - 1 { textIndex += 1 }
            }
        }
    }

    private func stopLoadingAnimation() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    func generate(from text: String, source: String) async {
        state = .loading
        startLoadingAnimation()
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
            stopLoadingAnimation()
            state = .success(mindMap)
        } catch {
            stopLoadingAnimation()
            state = .failure(error.localizedDescription)
        }
    }
}
