import Foundation

protocol PreferenceOption: CaseIterable, Hashable, Identifiable {
    var label: String { get }
}

nonisolated struct MindmapPreferences: Codable, Equatable, Sendable {
    var detail: Detail
    var complexity: Complexity
    var language: Language
    static let `default` = MindmapPreferences(detail: .medium, complexity: .standard, language: .english)
    
    enum Detail: String, CaseIterable, Identifiable, Codable, PreferenceOption {

        case low, medium, high
        var id: String { rawValue }
        var label: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
        var maxDepth: Int {
            switch self {
            case .low: return 2
            case .medium: return 3
            case .high: return 4
            }
        }
        var rootChildren: String {
            switch self {
            case .low: return "2 to 3"
            case .medium: return "3 to 5"
            case .high: return "4 to 6"
            }
        }
        var summaryWordCap: Int {
            switch self {
            case .low: return 10
            case .medium: return 15
            case .high: return 22
            }
        }
        var promptDescriptor: String {
            switch self {
            case .low: return "Keep the map very compact and still high level. Include only the most essential and crucial branches and details."
            case .medium: return "Make a balaned map that covers the key ideas without any overdetailing/overloading details"
            case .high: return "Make a complete rich and thorough map. Include add the supporting sub-points where useful"
            }
        }
    }
    enum Complexity: String, CaseIterable, Identifiable, Codable, PreferenceOption {
        case simple, standard, technical
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .simple: return "Low"
            case .standard: return "Medium"
            case .technical: return "High"
            }
        }
        var promptDescriptor: String {
            switch self {
            case .simple: return "Use a very simple words to explain. Use everyday language where a beginner understands and avoid jargons too"
            case .standard: return "Use a clear and neutral language the most people could understand"
            case .technical: return "Use technical and domain-specific terms where appropriate. Avoid jargon and use more complex language"
            }
        }
    }
    enum Language: String, CaseIterable, Codable, Identifiable, PreferenceOption {
        case english, bahasa
        var id: String { rawValue }
        var label: String {
            switch self {
            case .bahasa: return "Indonesia"
            case .english: return "English"
            }
        }
        var promptDescriptor: String {
            switch self {
            case .bahasa: return "Write every title and summary in Indonesian (Bahasa Indonesia)."
            case .english: return "Write every title and summary in English."
            }
        }
    }
}
