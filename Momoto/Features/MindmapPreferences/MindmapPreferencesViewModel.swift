import Foundation
import Combine

@MainActor
final class MindmapPreferencesViewModel: ObservableObject {
    
    @Published var detail: MindmapPreferences.Detail
    @Published var complexity: MindmapPreferences.Complexity
    @Published var language: MindmapPreferences.Language
    
    private let defaults: UserDefaults
    
    private enum Key {
        static let detail = "pref.detail"
        static let complexity = "pref.complexity"
        static let language = "pref.language"
    }
    //Pindahin semua enum yang ada didalem class ke dalem sebuah file bisa helper bisa model yang isinya enum
    //Bikin Separate Files namanya AppKeys
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let fallback = MindmapPreferences.default
        
        self.detail = defaults.string(forKey: Key.detail)
            .flatMap(MindmapPreferences.Detail.init(rawValue:)) ?? fallback.detail
        self.complexity = defaults.string(forKey: Key.complexity)
            .flatMap(MindmapPreferences.Complexity.init(rawValue:)) ?? fallback.complexity
        self.language = defaults.string(forKey: Key.language)
            .flatMap(MindmapPreferences.Language.init(rawValue:)) ?? fallback.language
    }
    
    var preferences: MindmapPreferences {
        MindmapPreferences(detail: detail, complexity: complexity, language: language)
    }
    
    private func persist() {
        defaults.set(detail.rawValue, forKey: Key.detail)
        defaults.set(complexity.rawValue, forKey: Key.complexity)
        defaults.set(language.rawValue, forKey: Key.language)
    }
    func submit (onGenerate: (MindmapPreferences) -> Void) {
        persist()
        onGenerate(preferences)
    }
}
