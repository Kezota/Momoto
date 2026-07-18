//
//  ChatbotViewModel.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import Foundation
import Combine

@MainActor
final class ChatbotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var draft: String = ""
    @Published var isThinking: Bool = false
    
    private let model: ChatbotService
    
    nonisolated init(model: ChatbotService = ChatbotService()) {
        self.model = model
    }
    
    func send(context: ModelContext) async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        
        messages.append(ChatMessage(role: .user, text: trimmed))
        draft = ""
        isThinking = true
        
        let answer = await model.chat(question: trimmed, history: messages, context: context)
        
        messages.append(ChatMessage(role: .assistant, text: answer))
        isThinking = false
    }
    
    func reset() {
        messages.removeAll()
        draft = ""
        isThinking = false
    }
}

