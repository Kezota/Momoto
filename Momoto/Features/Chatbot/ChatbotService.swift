//
//  FoundationModelService.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

#if canImport(FoundationModels)
import FoundationModels
#endif
import Foundation

struct ModelContext {
    var rawText: String
    var hierarchyOutline: String
    var selectedNodeTitle: String?
}

struct GeneratedNodeIdea {
    let title: String
    let icon: String
}

actor ChatbotService {
    
    func keywordExplanation(_ keyword: String, context: ModelContext) async -> String {
        let prompt = """
        Right now you are helping a dyslexic person to understand a passage that is scanned. The passage is: 
        \(context.rawText)
        , The mindmap hierarchy outline is
        \(context.hierarchyOutline). But now the dyslexic person is choosing one keyword in the mindmap and want to know the context and explanation to it. The keyword is
        \(keyword). Explain in one short sentence, use simple words and no technical words (no jargon) what does the keyword mean in the context of the passage.
        """
        return await generate(prompt: prompt, fallback: fallbackExplanation(for: keyword, context: context))
    }
    
    func chat(question: String, history: [ChatMessage], context: ModelContext) async -> String {
        let transcript = history.suffix(6).map { msg -> String in
            let who = msg.role == .user ? "User" : "Assistant"
            return "\(who): \(msg.text)"
        }.joined(separator: "\n")
        
        let selected = context.selectedNodeTitle.map{"Focused Branch: \($0)"} ?? ""
        
        let prompt = """
            You are a kind and friendly learning assistant/therapist for a reader with dyslexia where you are gonna be given with a passage
            \(context.rawText)
            with a mindmap outline
            \(context.hierarchyOutline)
            \(selected)
            Then the conversation so far is
            \(transcript)
            The user question is
            \(question)
            Please explain with a short 1-3 sentences. Maybe make a bullet point if possible but still explain it in short.
            """
        
        return await generate(prompt: prompt, fallback: fallbackChat(for: question, context: context))
    }

    func growIdeas(for nodeTitle: String, context: ModelContext) async -> [GeneratedNodeIdea] {
        let prompt = """
        You are helping brainstorm a mindmap. The mindmap hierarchy outline is
        \(context.hierarchyOutline)
        The node currently focused on is "\(nodeTitle)".
        Suggest 3 to 5 short, related sub-ideas that could become child nodes of "\(nodeTitle)".
        For each idea, also pick the single best matching icon name from this exact list (use one exactly as written, nothing else):
        \(MindmapIconLibrary.all.joined(separator: ", "))
        Reply with exactly one idea per line in this format, no numbering, no bullets, no extra explanation:
        Idea title|icon.name
        """
        let response = await generate(prompt: prompt, fallback: fallbackIdeas(for: nodeTitle))
        return parseIdeas(response, defaultIcon: "lightbulb")
    }

    func workBreakdown(for nodeTitle: String, context: ModelContext) async -> [GeneratedNodeIdea] {
        let prompt = """
        You are helping break a task down in a mindmap. The mindmap hierarchy outline is
        \(context.hierarchyOutline)
        The node currently focused on is "\(nodeTitle)".
        Break "\(nodeTitle)" down into 3 to 6 concrete, actionable sub-tasks that could become child nodes.
        For each sub-task, also pick the single best matching icon name from this exact list (use one exactly as written, nothing else):
        \(MindmapIconLibrary.all.joined(separator: ", "))
        Reply with exactly one sub-task per line in this format, no numbering, no bullets, no extra explanation:
        Sub-task title|icon.name
        """
        let response = await generate(prompt: prompt, fallback: fallbackWorkBreakdown(for: nodeTitle))
        return parseIdeas(response, defaultIcon: "checkmark.circle")
    }

    private func parseIdeas(_ text: String, defaultIcon: String) -> [GeneratedNodeIdea] {
        parseLines(text).map { line -> GeneratedNodeIdea in
            let parts = line.components(separatedBy: "|")
            let title = parts[0].trimmingCharacters(in: .whitespaces)
            let candidateIcon = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
            let icon = MindmapIconLibrary.all.contains(candidateIcon) ? candidateIcon : defaultIcon
            return GeneratedNodeIdea(title: title, icon: icon)
        }
        .filter { !$0.title.isEmpty }
    }

    private func parseLines(_ text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { line -> String in
                var trimmed = line.trimmingCharacters(in: .whitespaces)
                while let first = trimmed.first, "-*•".contains(first) {
                    trimmed.removeFirst()
                }
                if let dotIndex = trimmed.firstIndex(of: "."), trimmed[trimmed.startIndex..<dotIndex].allSatisfy(\.isNumber), !trimmed[trimmed.startIndex..<dotIndex].isEmpty {
                    trimmed.removeSubrange(trimmed.startIndex...dotIndex)
                }
                return trimmed.trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }

    private func generate(prompt: String, fallback: String) async -> String {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return content.isEmpty ? fallback : content
            } catch {
                return fallback
            }
        }
#endif
        return fallback
    }
}

private func fallbackExplanation(for keyword: String, context: ModelContext) -> String {
    let sentences = context.rawText
        .components(separatedBy: CharacterSet(charactersIn: ".!?"))
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)}
        .filter { !$0.isEmpty }
    
    if let match = sentences.first(where: {$0.lowercased().contains(keyword.lowercased())}) {
        return "\(keyword.capitalized) is one of the key ideas in this passage"
    }
    
    return "\(keyword.capitalized) is one of the key ideas in this passage."
}

private func fallbackChat(for question: String, context: ModelContext) -> String {
    let lower = question.lowercased()
    
    if lower.contains("main") || lower.contains("point") {
        return "The main point is: \(context.hierarchyOutline.split(separator: "\n").first.map(String.init) ?? "the scanned text")."
    }
    
    if lower.contains("summar") {
        let preview = context.rawText.split(separator: ".").prefix(2).joined(separator: ". ")
        return preview.isEmpty ? "There isn't enough text to summarise yet." : "\(preview)."
    }
    
    if let focus = context.selectedNodeTitle {
        return "The branch \"\(focus)\" is about one of the ideas in the passage. Tap to expand it and long-press for a short explanation."
    }
    
    return "Try long-pressing a branch for a one-line explanation, or ask me for a summary."
}

private func fallbackIdeas(for nodeTitle: String) -> String {
    """
    Related idea for \(nodeTitle)|lightbulb
    Another angle on \(nodeTitle)|sparkles
    Example of \(nodeTitle)|star
    """
}

private func fallbackWorkBreakdown(for nodeTitle: String) -> String {
    """
    Plan \(nodeTitle)|calendar
    Start \(nodeTitle)|flag
    Review \(nodeTitle)|checkmark.circle
    """
}

