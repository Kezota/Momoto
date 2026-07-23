//
//  SpeechNarrator.swift
//  Momoto
//
//  Created by Teresa Tendeas on 23/07/26.
//

import AVFoundation
import Combine

@MainActor
final class SpeechNarrator: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    // Speaks the given text, interrupting anything already playing.
    func speak(_ text: String, language: MindmapPreferences.Language) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)
        configureAudioSession()

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = Self.preferredVoice(for: language)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // Makes speech audible even when the ring/silent switch is on, and ducks other audio.
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }


    // Maps your app's language preference to a BCP-47 voice code.
    private static func languageCode(for language: MindmapPreferences.Language) -> String {
        switch language {
        case .english: return "en-US"
        case .bahasa:  return "id-ID"   // Indonesian
        }
    }

    // Best-quality installed voice for that language, else the standard voice for it.
    private static func preferredVoice(for language: MindmapPreferences.Language) -> AVSpeechSynthesisVoice? {
        let code = languageCode(for: language)
        let prefix = String(code.prefix(2))   // "en" or "id"
        let matches = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(prefix) }

        return matches.first(where: { $0.quality == .premium })
            ?? matches.first(where: { $0.quality == .enhanced })
            ?? AVSpeechSynthesisVoice(language: code)
    }
}
