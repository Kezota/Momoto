//
//  TextToNodeService.swift
//  MomotoMindmap
//
//  Created by Teresa Tendeas on 04/05/26.
//

import Foundation
import FoundationModels

// Placeholder for AI, exclude UUID & isExpanded from MindMapNode
private struct NodeDTO: Codable {
    let title: String
    let summary: String?
    let symbol: String?
    let children: [NodeDTO]?
}

enum TextToNodeError: LocalizedError {
    case inputTooShort
    case invalidJSON(String)
    case emptyResult
    case aiFailure(String)

    var errorDescription: String? {
        switch self {
        case .inputTooShort:
            return "Input text is too short to generate a mind map."
        case .invalidJSON(let detail):
            return "Failed to parse AI response as JSON: \(detail)"
        case .emptyResult:
            return "AI returned an empty response."
        case .aiFailure(let detail):
            return "AI processing failed: \(detail)"
        }
    }
}


final class TextToNodeService {
    func generateMindMap(from text: String) async throws -> MindMapNode {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else { throw TextToNodeError.inputTooShort }

        let jsonString = try await requestAIResponse(for: trimmed)
        return try decode(jsonString: jsonString)
    }

    private func requestAIResponse(for text: String) async throws -> String {
        let prompt = buildPrompt(for: text)

        let model = SystemLanguageModel.default
        let session = LanguageModelSession(model: model)

        let response: LanguageModelSession.Response<String>
        do {
            response = try await session.respond(to: prompt)
        } catch {
            throw TextToNodeError.aiFailure(error.localizedDescription)
        }

        let raw = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { throw TextToNodeError.emptyResult }
        return raw
    }

    // AI Prompt
    private func buildPrompt(for text: String) -> String {
        """
        You are a mind map generator. Convert the text below into a strict JSON tree.

        RULES:
        - Output ONLY valid JSON. No markdown, no code fences, no extra text.
        - Root node title: 1–3 words capturing the main topic.
        - Maximum 3 levels deep: root → branches → leaves.
        - Every title MUST be 1–3 words (concise label, not a sentence).
        - Every summary MUST be exactly 1 short sentence (max 15 words).
        - Every symbol MUST be a valid SF Symbols name (e.g. "star", "bolt", "leaf", "circle", "heart", "flag", "book", "lightbulb", "cpu", "network", "person", "cloud", "lock", "globe", "chart.bar").
        - No duplicate titles anywhere in the tree.
        - No generic filler nodes like "Introduction" or "Conclusion".
        - Children array must exist on every node (use [] if no children).
        - Do NOT wrap JSON in ```json or any other markers.

        JSON SCHEMA:
        {
          "title": "string (1-3 words)",
          "summary": "string (1 sentence)",
          "symbol": "string (SF Symbol)",
          "children": [ /* same schema recursively */ ]
        }

        TEXT TO CONVERT:
        \(text)
        """
    }
    
    // Helper functions
    private func decode(jsonString: String) throws -> MindMapNode {
        let cleaned = extractJSON(from: jsonString)
        guard let data = cleaned.data(using: .utf8) else {
            throw TextToNodeError.invalidJSON("Cannot convert string to UTF-8 data.")
        }

        let decoder = JSONDecoder()
        let dto: NodeDTO
        do {
            dto = try decoder.decode(NodeDTO.self, from: data)
        } catch {
            throw TextToNodeError.invalidJSON(error.localizedDescription)
        }

        return map(dto: dto)
    }

    private func extractJSON(from raw: String) -> String {
        if let start = raw.firstIndex(of: "{"),
           let end = raw.lastIndex(of: "}") {
            return String(raw[start...end])
        }
        return raw
    }

    private func map(dto: NodeDTO) -> MindMapNode {
        MindMapNode(
            id: UUID(),
            title: dto.title,
            symbol: dto.symbol ?? "circle",
            summary: dto.summary ?? "",
            children: (dto.children ?? []).map { map(dto: $0) },
            isExpanded: true
        )
    }
}
