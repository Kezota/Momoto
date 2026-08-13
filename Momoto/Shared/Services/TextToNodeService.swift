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
    
    func generateMindMap(from text: String, preferences: MindmapPreferences) async throws -> MindMapNode {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else { throw TextToNodeError.inputTooShort }

        let jsonString = try await requestAIResponse(for: trimmed, preferences: preferences)
        return try decode(jsonString: jsonString)
    }

    private func requestAIResponse(for text: String, preferences: MindmapPreferences) async throws -> String {
        let prompt = buildPrompt(for: text, preferences: preferences)
        
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
    private func buildPrompt(for text: String, preferences: MindmapPreferences) -> String {
        """
        You are a deterministic mind map generator.

        Your task is to convert the given text into a STRICT JSON tree.

        OUTPUT REQUIREMENTS:
        - Output ONLY valid JSON.
        - Do NOT include markdown, code fences, explanations, or extra text.
        - The output MUST be parseable by a JSON parser without modification.

        STRUCTURE RULES:
        - Maximum depth: \(preferences.detail.maxDepth) levels (root → branches → leaves).
        - Root must have \(preferences.detail.rootChildren) children unless input is extremely short.
        - Each node MUST include: title, summary, symbol, children.
        - "children" MUST always exist (use [] if empty).

        CONTENT RULES:
        - Extract the INFORMATION in the text, not its structure. Do NOT copy the text's
          headings or section names as nodes; a heading is only a pointer to content. Read what
          is written under it and turn the actual facts, claims, causes, and examples into nodes.
        - Titles: 2–6 words, no end punctuation.
        - A title MUST state an idea, fact, or claim on its own: prefer
          "Cells Make Their Own Energy" over "Energy",
          "Warm Up Before Running" over "Before".
        - NEVER use a single vague word as a title (e.g. Before, After, Causes, Effects, Types).
          Attach it to its subject: "Causes of Inflation", "Effects on Sleep".
        - No duplicate titles anywhere.
        - No generic labels (e.g., Introduction, Overview, Conclusion).

        SUMMARY RULES:
        - 1 to 2 sentences, maximum \(preferences.detail.summaryWordCap) words total.
        - The summary must TEACH the content of that node: include the specific facts, numbers,
          names, reasons, or examples the text gives. Someone reading only the summaries should
          understand the passage without opening the original text.
        - NEVER merely restate or pad the title. If the text says why or how, the summary says
          why or how.
        - BAD:  title "Photosynthesis Needs Sunlight", summary "This is about photosynthesis and sunlight."
        - GOOD: title "Photosynthesis Needs Sunlight", summary "Chlorophyll absorbs sunlight to turn water and CO2 into glucose, which the plant uses as food."

        PERSONALIZATION:
        - Detail: \(preferences.detail.promptDescriptor)
        - Complexity: \(preferences.complexity.promptDescriptor)
        - Language: \(preferences.language.promptDescriptor)

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
