//
//  TextToNodeService.swift
//  MomotoMindmap
//
//  Created by Teresa Tendeas on 04/05/26.
//

import UIKit
import Foundation
import FoundationModels

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
        You are a deterministic mind map generator.

        Your task is to convert the given text into a STRICT JSON tree.

        OUTPUT REQUIREMENTS:
        - Output ONLY valid JSON.
        - Do NOT include markdown, code fences, explanations, or extra text.
        - The output MUST be parseable by a JSON parser without modification.

        STRUCTURE RULES:
        - Maximum depth: 3 levels (root → branches → leaves).
        - Root must always have at least 2 children unless input is extremely short.
        - Each node MUST include: title, summary, symbol, children.
        - "children" MUST always exist (use [] if empty).

        CONTENT RULES:
        - Titles: 1–3 words, concise, no punctuation.
        - No duplicate titles anywhere.
        - No generic labels (e.g., Introduction, Overview, Conclusion).

        SUMMARY RULES:
        - Exactly 1 sentence.
        - Maximum 15 words.
        - Must be meaningful and descriptive (not fragments).

        SYMBOL RULES:
        - Use ONLY simple, safe SF Symbols:
          ["star","bolt","leaf","circle","heart","flag","book","lightbulb","cpu","network","person","cloud","lock","globe","chart.bar"]
        - DO NOT invent new symbols.
        - DO NOT use suffixes (.fill, .circle, etc.).

        FAILURE HANDLING:
        - If input is unclear or too short, still produce a valid minimal tree.
        - Never break JSON format under any condition.

        JSON SCHEMA:
        {
          "title": "string",
          "summary": "string",
          "symbol": "string",
          "children": [ ... ]
        }

        TEXT:
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
        let rawSymbol = dto.symbol ?? "circle"
        let validatedSymbol = UIImage(systemName: rawSymbol) != nil ? rawSymbol : "circle"
        
        return MindMapNode(
            id: UUID(),
            title: dto.title,
            symbol: validatedSymbol,
            summary: dto.summary ?? "",
            children: (dto.children ?? []).map { map(dto: $0) },
            isExpanded: true
        )
    }
}
