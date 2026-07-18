# Learning Module — Building a "Personalize Your Mindmap" Preferences Screen (SwiftUI / iOS)

> This is a **self-contained learning context**. It teaches the concepts from scratch, walks through building the feature step by step, then gives a quiz, hands-on "edit it yourself" challenges, and a complete copy‑paste list of every file that was created or changed.
>
> Target app: **Momoto** — a SwiftUI iOS app that turns text (pasted, from PDF, scanned, or a photo) into an interactive mindmap using Apple's on‑device `FoundationModels`.
>
> Feature built: a **preferences card** that appears *after* the user gives input and *before* the mindmap is generated, letting the user personalize the output (how detailed, how complex the wording, what to focus on). Those choices are then injected into the AI prompt.

---

## 0. Learning objectives

By the end you should be able to explain and reproduce, from scratch:

1. **Enums as a data model** — Swift enums with raw values plus computed properties that turn a case into UI text and AI‑prompt text.
2. **Protocols + generics** — defining a `PreferenceOption` protocol and a single reusable `PreferenceCard<Option>` view that works for *any* preference enum.
3. **MVVM in SwiftUI** — a `View` that owns a `ViewModel` (`ObservableObject`) and binds to its `@Published` state.
4. **SwiftUI property wrappers** — `@StateObject`, `@Published`, `@Binding`, `@EnvironmentObject`.
5. **Navigation** — `NavigationStack` driven by a `NavigationPath`, with an `enum` route (`AppRoute`) and `navigationDestination`.
6. **Persistence** — remembering the user's choices across launches with `UserDefaults`.
7. **Prompt engineering in code** — building an LLM prompt with Swift string interpolation so user choices change the AI's behavior.
8. **A concurrency footnote** — why a plain value‑type model is marked `nonisolated`/`Sendable`.

---

## 1. The big picture — where this fits

### App flow (before)
```
Home ──▶ [Paste / PDF / Scan / Photo] ──▶ Processing (AI generates) ──▶ Mindmap
```

### App flow (after — our feature inserts ONE new step)
```
Home ──▶ [Paste / PDF / Scan / Photo] ──▶ ✨Preferences✨ ──▶ Processing (AI) ──▶ Mindmap
```

### The key architectural insight: one chokepoint
All four input methods already funnel their extracted text through **one** function in `HomeView`:

```swift
private func processInput(_ text: String) {
    appState.pendingInputText = text
    appState.path.append(AppRoute.processing)   // ← was this
}
```

Because every input path passes through here, inserting the preferences screen for *all* of them is a **one‑line change** (push `.preferences` instead of `.processing`). This is a recurring lesson: *find the single place where flows converge, and you change behavior everywhere at once.*

### The data's journey
```
PreferencesView (user taps pills)
   │  selections live in MindmapPreferencesViewModel (@Published)
   ▼  on "Generate", build a MindmapPreferences value + save to UserDefaults
AppState.pendingPreferences   ← stored on the shared app state
   ▼
ProcessingView reads it ──▶ ProcessingViewModel.generate(..., preferences:)
   ▼
TextToNodeService.generateMindMap(from:preferences:)
   ▼
buildPrompt(...) interpolates the preferences into the AI prompt string
```

---

## 2. Concepts primer (read this before building)

### 2.1 Enums with raw values + computed properties
A Swift `enum` can have a **raw value** (here `String`) and also expose **computed properties** that map each case to other things. We use one enum per preference dimension. Each case knows:
- its **UI label** (`"Concise"`),
- the **numbers/text** to feed the AI (`maxDepth`, `summaryWordCap`, `promptDescriptor`).

This keeps all knowledge about "what *Concise* means" in **one place**, instead of scattering `if` statements around the app.

```swift
enum Detail: String, CaseIterable, Codable {
    case concise, balanced, detailed

    var label: String { … }          // for the UI
    var maxDepth: Int { … }           // for the prompt
    var promptDescriptor: String { … }// for the prompt
}
```
- `String` raw value → lets us save/restore it as text in `UserDefaults` and encode it with `Codable`.
- `CaseIterable` → gives us `Detail.allCases`, so the UI can loop over every option automatically.

### 2.2 Protocols + generics — write the card ONCE
We have three different enums (`Detail`, `Complexity`, `Focus`). Without generics you'd write three almost‑identical card views. Instead we define a **protocol** describing "anything that can be a pill option":

```swift
protocol PreferenceOption: CaseIterable, Hashable, Identifiable {
    var label: String { get }
}
```

Then a **generic** view works for any type that conforms:

```swift
struct PreferenceCard<Option: PreferenceOption>: View { … }
```

`PreferenceCard<Detail>`, `PreferenceCard<Complexity>`, `PreferenceCard<Focus>` are all the *same code*. This is the **DRY principle** (Don't Repeat Yourself) in action.

### 2.3 MVVM
- **Model** = `MindmapPreferences` (plain data: what did the user choose).
- **ViewModel** = `MindmapPreferencesViewModel` (`ObservableObject`): holds the live selections, loads/saves them, exposes a `submit(...)`.
- **View** = `PreferencesView` (SwiftUI): draws the cards, binds to the view model, has no business logic.

Why separate them? The view model can be tested and reasoned about without any UI, and the view stays "dumb" and easy to restyle.

### 2.4 Property wrappers you'll see
| Wrapper | Where | Meaning |
|---|---|---|
| `@StateObject` | `PreferencesView` owns the VM | "I create and own this object's lifetime." |
| `@Published` | VM properties | "When I change, re‑render any view watching me." |
| `@Binding` | `PreferenceCard.selection` | "I don't own this value; I read & write someone else's." |
| `@EnvironmentObject` | `AppState` in views | "Injected from above; shared app‑wide." |

`$viewModel.detail` (the `$`) creates a **`Binding`** to that published property — that's how the child card can change the parent's value.

### 2.5 Navigation: a path + an enum of routes
The app uses `NavigationStack(path: $appState.path)`. `path` is a `NavigationPath` (an array‑like stack). To go somewhere you `append` a route value; to go back you remove one. The route is an `enum`:

```swift
enum AppRoute: Hashable {
    case scan, pdf, paste, preferences, processing
    case mindmap(MindMap)
    …
}
```
`navigationDestination(for: AppRoute.self) { route in … }` is the single switch that maps each route to the screen it shows.

### 2.6 Persistence with UserDefaults
`UserDefaults` is a tiny key→value store that survives app restarts — perfect for small preferences. We save three strings (the raw values) and read them back on launch, falling back to defaults if absent/unknown.

### 2.7 Prompt engineering in code
The AI prompt is just a big Swift string. With **string interpolation** (`\(…)`) we drop the user's chosen numbers and instructions into it, so different choices literally produce a different prompt and therefore a different mindmap.

### 2.8 Concurrency footnote: `nonisolated` / `Sendable`
This project compiles with Swift's strict concurrency where top‑level declarations can default to the **main actor**. Our model is a pure value type that the *background* AI service reads, so we mark it `nonisolated` (not tied to the main actor) and `Sendable` (safe to pass between threads). Without it the compiler warns when the non‑main‑actor service touches `MindmapPreferences.default`.

---

## 3. Build it from scratch — step by step

> Do these in order. After each step the project should still compile (except where a step references something the *next* step adds — noted inline).

### Step 1 — The model: `MindmapPreferences.swift`
**Folder:** `Momoto/Shared/Models/`
**Why first:** everything else refers to these types.
**Concepts:** enums + raw values, computed properties, protocol, `Codable`, `CaseIterable`, `nonisolated`/`Sendable`.

Key ideas to notice while you type it:
- One `enum` per dimension; each case maps to a `label` (UI) and prompt data.
- `static let default` gives a balanced starting point and a fallback.
- The `PreferenceOption` protocol is what lets the card be generic.

### Step 2 — The view model: `MindmapPreferencesViewModel.swift`
**Folder:** `Momoto/Features/MindmapPreferences/`
**Concepts:** `ObservableObject`, `@Published`, `UserDefaults` load/save, dependency injection (`init(defaults:)` for testability).

Notice:
- `init` **seeds** the three `@Published` values from `UserDefaults`, using `flatMap(Enum.init(rawValue:))` and `?? fallback` so a missing or corrupted value safely becomes the default.
- `submit(onGenerate:)` **persists** then hands a finished `MindmapPreferences` back to the caller via a closure — the VM doesn't know anything about navigation.

### Step 3 — The reusable component: `PreferenceCard.swift`
**Folder:** `Momoto/Features/MindmapPreferences/Components/`
**Concepts:** generic SwiftUI view, `@Binding`, `ForEach(Array(Option.allCases))`, building a styled card with the app `Theme`.

Notice:
- `PreferenceCard<Option: PreferenceOption>` — one component, three uses.
- The selected pill fills with `Theme.purple`; unselected pills use the background + a stroke.
- `withAnimation` on the tap gives the smooth selection transition.

### Step 4 — The screen: `PreferencesView.swift`
**Folder:** `Momoto/Features/MindmapPreferences/`
**Concepts:** `@StateObject` ownership, composing three `PreferenceCard`s, a pinned bottom action button, `onGenerate` callback.

Notice:
- It owns the VM with `@StateObject`.
- It passes `$viewModel.detail` (a binding) into each card.
- The bottom button calls `viewModel.submit(onGenerate:)`, forwarding the result up to whoever presented this screen.

### Step 5 — Register a route: `AppRoute.swift`
**Folder:** `Momoto/App/`
Add one case: `case preferences`. (One line.)

### Step 6 — Wire it into shared state + Home: `HomeView.swift`
**Folder:** `Momoto/Features/Home/`
Three small edits:
1. Add `@Published var pendingPreferences: MindmapPreferences = .default` to `AppState`.
2. In `processInput`, push `.preferences` instead of `.processing`.
3. Add a `navigationDestination` case for `.preferences` that shows `PreferencesView` and, on generate, stores the prefs and pushes `.processing`.

### Step 7 — Thread prefs through Processing
**Files:** `ProcessingViewModel.swift`, `ProcessingView.swift`
- `generate(from:source:)` becomes `generate(from:preferences:source:)`.
- The two call sites in `ProcessingView` (the `.task` and the "Try Again" button) pass `appState.pendingPreferences`.

### Step 8 — Inject prefs into the prompt: `TextToNodeService.swift`
**Folder:** `Momoto/Shared/Services/`
- `generateMindMap(from:preferences:)` (defaulted so old callers/tests still compile).
- `buildPrompt(for:preferences:)` interpolates `detail.maxDepth`, `detail.rootChildren`, `detail.summaryWordCap`, `detail.promptDescriptor`, `complexity.promptDescriptor`, and `focus.promptDescriptor` into the prompt.

**Build & run.** Pick any input method, type some text, and you'll land on the new card before generation.

---

## 4. Quiz

Try to answer before peeking at the **Answer key** below.

**Conceptual**
1. Why does inserting the preferences screen only require changing one line in `HomeView`, even though there are four input methods?
2. What does conforming `Detail` to `CaseIterable` give you, and where is it used in the UI?
3. Explain the difference between `@StateObject` and `@Binding` using `PreferencesView` and `PreferenceCard` as the example.
4. Why is the AI prompt logic kept in `buildPrompt` rather than in the view?
5. Why is `MindmapPreferences` marked `nonisolated` and `Sendable`?

**Code reading**
6. In the view model's `init`, what happens if `UserDefaults` contains `"banana"` for the `pref.detail` key? Which line handles it and what's the result?
7. What is the type of `$viewModel.detail`, and why does the card need that type instead of just `MindmapPreferences.Detail`?
8. `generateMindMap(from:preferences:)` has `preferences: MindmapPreferences = .default`. Why include the `= .default`?
9. In `buildPrompt`, what does `\(detail.maxDepth >= 3 ? " → leaves" : "")` produce for `.concise` vs `.detailed`, and why?

**Design / "what if"**
10. If you wanted the choices to reset every launch instead of persisting, what single method would you change and how?
11. The protocol currently only requires `label`. Two enums (`Complexity`, `Focus`) still define a `caption` property that nothing uses. What are two clean ways to resolve that, and what's the trade‑off?

---

## 5. Edit‑it‑yourself challenges (graduated)

Do these directly in the code. Each builds a real skill.

**Warm‑up**
- **A.** Change the *Detailed* option so its `summaryWordCap` is `30` instead of `22`. Predict how the generated summaries change, then test.
- **B.** Change the header subtitle text and the bottom button label.

**Core**
- **C. Re‑add live captions.** Put the `caption` back into the `PreferenceOption` protocol, give `Detail` a `caption`, and show `selection.caption` under the pills in `PreferenceCard`. (This reverses a simplification — great for understanding protocol requirements.)
- **D. Add a fourth Detail option** `case exhaustive`. The compiler will force you to handle it in every `switch` — notice how exhaustive enums make refactors safe.
- **E. Add a brand‑new dimension** `Length` (`short` / `medium` / `long`) end‑to‑end: model enum, a 4th `PreferenceCard` in the view, and inject it into `buildPrompt`.

**Stretch**
- **F. "Reset to defaults" button.** Add a method on the VM that sets all three back to `MindmapPreferences.default` (and persists), and a secondary button (`SecondaryButtonStyle`) on the screen that calls it.
- **G. Persist as one JSON blob.** Replace the three `UserDefaults` string keys with a single `Codable` round‑trip: encode `MindmapPreferences` to `Data` and store it under one key. Discuss the trade‑offs vs three keys.
- **H. Write a unit test** asserting that `buildPrompt` for `.concise` contains `"Maximum depth: 2"` and for `.detailed` contains `"Maximum depth: 3"`. (You may need to make `buildPrompt` `internal` and add a test target.)

**Reflection prompts (write a sentence each)**
- Where else in this app could the "single chokepoint" idea simplify a future feature?
- If a designer asked for a totally different card look, how many files would you touch — and why is that number small?

---

## 6. Exact change list (copy‑paste)

> 4 new files, 5 edited files. The Xcode project uses file‑system‑synchronized groups, so dropping new `.swift` files anywhere under `Momoto/` auto‑includes them — no manual `project.pbxproj` editing needed.

### 🆕 NEW FILE 1 — `Momoto/Shared/Models/MindmapPreferences.swift`
```swift
//
//  MindmapPreferences.swift
//  Momoto
//
//  User-selected preferences that personalize the generated mindmap.
//

import Foundation

// MARK: - Preference option protocol

/// A single selectable preference option, used to drive the pill UI generically.
protocol PreferenceOption: CaseIterable, Hashable, Identifiable {
    /// Short text shown on the pill (e.g. "Concise").
    var label: String { get }
}

// MARK: - MindmapPreferences

nonisolated struct MindmapPreferences: Codable, Equatable, Sendable {
    var detail: Detail
    var complexity: Complexity
    var focus: Focus

    static let `default` = MindmapPreferences(
        detail: .balanced,
        complexity: .standard,
        focus: .overview
    )

    // MARK: Detail — controls summary richness AND tree size/depth together.
    enum Detail: String, CaseIterable, Codable, Identifiable, PreferenceOption {
        case concise, balanced, detailed
        var id: String { rawValue }

        var label: String {
            switch self {
            case .concise:  return "Concise"
            case .balanced: return "Balanced"
            case .detailed: return "Detailed"
            }
        }

        // Numeric parameters injected into the AI prompt.
        var maxDepth: Int {
            switch self {
            case .concise:            return 2
            case .balanced, .detailed: return 3
            }
        }
        var rootChildren: String {
            switch self {
            case .concise:  return "2 to 3"
            case .balanced: return "3 to 5"
            case .detailed: return "4 to 6"
            }
        }
        var summaryWordCap: Int {
            switch self {
            case .concise:  return 10
            case .balanced: return 15
            case .detailed: return 22
            }
        }

        var promptDescriptor: String {
            switch self {
            case .concise:
                return "Keep the map small and high-level. Include only the most essential branches."
            case .balanced:
                return "Produce a balanced map covering the key ideas without overloading detail."
            case .detailed:
                return "Produce a rich, thorough map. Include supporting sub-points and nuance where useful."
            }
        }
    }

    // MARK: Complexity — controls wording / vocabulary register.
    enum Complexity: String, CaseIterable, Codable, Identifiable, PreferenceOption {
        case simple, standard, technical
        var id: String { rawValue }

        var label: String {
            switch self {
            case .simple:    return "Simple"
            case .standard:  return "Standard"
            case .technical: return "Technical"
            }
        }

        var caption: String {
            switch self {
            case .simple:    return "Beginner-friendly, everyday words."
            case .standard:  return "Clear, neutral wording."
            case .technical: return "Precise, domain-specific terms."
            }
        }

        var promptDescriptor: String {
            switch self {
            case .simple:
                return "Use simple, everyday language a beginner understands. Avoid jargon."
            case .standard:
                return "Use clear, neutral language."
            case .technical:
                return "Use precise technical and domain-specific terminology where appropriate."
            }
        }
    }

    // MARK: Focus — controls what the AI emphasizes.
    enum Focus: String, CaseIterable, Codable, Identifiable, PreferenceOption {
        case study, overview, brainstorm
        var id: String { rawValue }

        var label: String {
            switch self {
            case .study:      return "Study"
            case .overview:   return "Overview"
            case .brainstorm: return "Brainstorm"
            }
        }

        var caption: String {
            switch self {
            case .study:      return "Facts and definitions to memorize."
            case .overview:   return "The big themes and how they relate."
            case .brainstorm: return "Related ideas and possibilities."
            }
        }

        var promptDescriptor: String {
            switch self {
            case .study:
                return "Optimize for memorization: short memorable titles, key facts, definitions, and cause/effect."
            case .overview:
                return "Optimize for a high-level overview: the most important themes and how they relate."
            case .brainstorm:
                return "Optimize for idea generation: include related and adjacent concepts and possibilities."
            }
        }
    }
}
```
> 🧠 Teaching note: `Complexity.caption` and `Focus.caption` are currently **unused** (the protocol no longer requires `caption`, and the UI doesn't show it). That's deliberate dead code left for **Challenge C**. In production you'd either wire it back into the UI or delete it.

### 🆕 NEW FILE 2 — `Momoto/Features/MindmapPreferences/MindmapPreferencesViewModel.swift`
```swift
//
//  MindmapPreferencesViewModel.swift
//  Momoto
//
//  Holds the user's in-flight preference selections and persists them
//  between sessions via UserDefaults.
//

import Foundation
import Combine

@MainActor
final class MindmapPreferencesViewModel: ObservableObject {

    @Published var detail: MindmapPreferences.Detail
    @Published var complexity: MindmapPreferences.Complexity
    @Published var focus: MindmapPreferences.Focus

    private let defaults: UserDefaults

    private enum Key {
        static let detail = "pref.detail"
        static let complexity = "pref.complexity"
        static let focus = "pref.focus"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let fallback = MindmapPreferences.default

        // Seed from persistence; unknown / absent values fall back to defaults.
        self.detail = defaults.string(forKey: Key.detail)
            .flatMap(MindmapPreferences.Detail.init(rawValue:)) ?? fallback.detail
        self.complexity = defaults.string(forKey: Key.complexity)
            .flatMap(MindmapPreferences.Complexity.init(rawValue:)) ?? fallback.complexity
        self.focus = defaults.string(forKey: Key.focus)
            .flatMap(MindmapPreferences.Focus.init(rawValue:)) ?? fallback.focus
    }

    var preferences: MindmapPreferences {
        MindmapPreferences(detail: detail, complexity: complexity, focus: focus)
    }

    private func persist() {
        defaults.set(detail.rawValue, forKey: Key.detail)
        defaults.set(complexity.rawValue, forKey: Key.complexity)
        defaults.set(focus.rawValue, forKey: Key.focus)
    }

    /// Persists the current selections and hands them back to the caller.
    func submit(onGenerate: (MindmapPreferences) -> Void) {
        persist()
        onGenerate(preferences)
    }
}
```

### 🆕 NEW FILE 3 — `Momoto/Features/MindmapPreferences/Components/PreferenceCard.swift`
```swift
//
//  PreferenceCard.swift
//  Momoto
//
//  A themed card showing one preference dimension as a row of selectable pills.
//

import SwiftUI

struct PreferenceCard<Option: PreferenceOption>: View {

    let icon: String
    let title: String
    @Binding var selection: Option

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header: icon chip + title
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.purple)
                    .frame(width: 30, height: 30)
                    .background(Theme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }

            // Pills
            HStack(spacing: 8) {
                ForEach(Array(Option.allCases)) { option in
                    pill(option)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .shadow(color: Theme.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
    }

    private func pill(_ option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { selection = option }
        } label: {
            Text(option.label)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(isSelected ? Theme.white : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    Capsule().fill(isSelected ? Theme.purple : Theme.background)
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Theme.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
```

### 🆕 NEW FILE 4 — `Momoto/Features/MindmapPreferences/PreferencesView.swift`
```swift
//
//  PreferencesView.swift
//  Momoto
//
//  Lets the user personalize the mindmap output before generation.
//

import SwiftUI

struct PreferencesView: View {

    @StateObject private var viewModel = MindmapPreferencesViewModel()

    /// Called with the chosen preferences when the user taps "Generate Mindmap".
    var onGenerate: (MindmapPreferences) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        PreferenceCard(
                            icon: "slider.horizontal.3",
                            title: "Detail",
                            selection: $viewModel.detail
                        )
                        PreferenceCard(
                            icon: "textformat.size",
                            title: "Complexity",
                            selection: $viewModel.complexity
                        )
                        PreferenceCard(
                            icon: "scope",
                            title: "Focus",
                            selection: $viewModel.focus
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }

                generateBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Customize your mindmap")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)

            Text("Choose your preferences!")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var generateBar: some View {
        Button("Generate Mindmap") {
            viewModel.submit(onGenerate: onGenerate)
        }
        .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            Theme.background
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Theme.black.opacity(0.05), radius: 10, x: 0, y: -4)
        )
    }
}

#Preview {
    NavigationStack {
        PreferencesView(onGenerate: { _ in })
    }
}
```

---

### ✏️ EDITED FILE 5 — `Momoto/App/AppRoute.swift`
Add one case (`preferences`) between `paste` and `processing`:
```swift
enum AppRoute: Hashable {
    case scan
    case pdf
    case paste
    case preferences      // ← ADDED
    case processing
    case mindmap(MindMap)
    case chatbot
    case history
    case photo
}
```

### ✏️ EDITED FILE 6 — `Momoto/Features/Home/HomeView.swift`
**6a.** Add `pendingPreferences` to `AppState`:
```swift
class AppState: ObservableObject {
    @Published var path = NavigationPath()
    @Published var pendingInputText = ""
    @Published var pendingPreferences: MindmapPreferences = .default   // ← ADDED
}
```

**6b.** Add a `navigationDestination` case for `.preferences` (inside the `switch route` in `.navigationDestination`, right after the `.paste` case):
```swift
                case .paste:
                    PasteTextView(onSubmit: processInput)
                case .preferences:                                     // ← ADDED block
                    PreferencesView(onGenerate: { preferences in
                        appState.pendingPreferences = preferences
                        appState.path.append(AppRoute.processing)
                    })
                case .processing:
                    ProcessingView()
```

**6c.** In `processInput`, push `.preferences` instead of `.processing`:
```swift
    private func processInput(_ text: String) {
        appState.pendingInputText = text
        appState.path.append(AppRoute.preferences)   // ← CHANGED (was .processing)
    }
```

### ✏️ EDITED FILE 7 — `Momoto/Shared/Services/TextToNodeService.swift`
**7a.** `generateMindMap` gains a defaulted `preferences` parameter and forwards it:
```swift
    func generateMindMap(from text: String, preferences: MindmapPreferences = .default) async throws -> MindMapNode {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else { throw TextToNodeError.inputTooShort }

        let jsonString = try await requestAIResponse(for: trimmed, preferences: preferences)
        return try decode(jsonString: jsonString)
    }
```

**7b.** `requestAIResponse` takes & forwards `preferences`:
```swift
    private func requestAIResponse(for text: String, preferences: MindmapPreferences) async throws -> String {
        let prompt = buildPrompt(for: text, preferences: preferences)
        // …unchanged below…
```

**7c.** `buildPrompt` becomes preference‑driven. The STRUCTURE / SUMMARY rules now interpolate values, and a new LANGUAGE & FOCUS section is added:
```swift
    // AI Prompt
    private func buildPrompt(for text: String, preferences: MindmapPreferences) -> String {
        let detail = preferences.detail
        return """
        You are a deterministic mind map generator.

        Your task is to convert the given text into a STRICT JSON tree.

        OUTPUT REQUIREMENTS:
        - Output ONLY valid JSON.
        - Do NOT include markdown, code fences, explanations, or extra text.
        - The output MUST be parseable by a JSON parser without modification.

        STRUCTURE RULES:
        - Maximum depth: \(detail.maxDepth) levels (root → branches\(detail.maxDepth >= 3 ? " → leaves" : "")).
        - Root must have \(detail.rootChildren) children unless input is extremely short.
        - Each node MUST include: title, summary, symbol, children.
        - "children" MUST always exist (use [] if empty).
        - \(detail.promptDescriptor)

        CONTENT RULES:
        - Titles: 1–3 words, concise, no punctuation.
        - No duplicate titles anywhere.
        - No generic labels (e.g., Introduction, Overview, Conclusion).

        SUMMARY RULES:
        - Exactly 1 sentence.
        - Maximum \(detail.summaryWordCap) words.
        - Must be meaningful and descriptive (not fragments).

        LANGUAGE & FOCUS:
        - \(preferences.complexity.promptDescriptor)
        - \(preferences.focus.promptDescriptor)

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
```
> Everything below `buildPrompt` (`decode`, `extractJSON`, `map`) is **unchanged**.

### ✏️ EDITED FILE 8 — `Momoto/Features/Processing/ProcessingViewModel.swift`
`generate` gains `preferences` and passes it to the service:
```swift
    func generate(from text: String, preferences: MindmapPreferences, source: String) async {
        state = .loading
        startLoadingAnimation()
        let trimmedText = String(text.prefix(maxCharacters))
        do {
            let rootNode = try await service.generateMindMap(from: trimmedText, preferences: preferences)
            // …unchanged below…
```

### ✏️ EDITED FILE 9 — `Momoto/Features/Processing/ProcessingView.swift`
Both call sites now pass `appState.pendingPreferences`:
```swift
        // the .task modifier:
        .task { await viewModel.generate(from: appState.pendingInputText, preferences: appState.pendingPreferences, source: "App") }
```
```swift
        // the "Try Again" button:
        Button("Try Again") { Task { await viewModel.generate(from: appState.pendingInputText, preferences: appState.pendingPreferences, source: "App") } }
```

---

## 7. Answer key (for Section 4)

1. Because all four input methods converge on the single `processInput(_:)` function. Changing the route it pushes (`.processing` → `.preferences`) redirects every path at once.
2. `CaseIterable` synthesizes `allCases`, an array of every case. The card iterates it with `ForEach(Array(Option.allCases))` to render one pill per option — add a case and the UI updates automatically.
3. `@StateObject` means `PreferencesView` **creates and owns** the view model for its lifetime. `@Binding` in `PreferenceCard` means the card **doesn't own** the value — it reads/writes a value owned by the view model (passed as `$viewModel.detail`). Owner vs. borrower.
4. Separation of concerns/testability: the view should only display state. Prompt logic lives in the service so it can change independently, be unit‑tested, and be reused without any UI.
5. The project's strict concurrency defaults top‑level declarations toward the main actor. The background AI service reads the model off the main actor, so marking it `nonisolated` + `Sendable` says "this is a thread‑safe value type, safe to use anywhere," silencing the warning and documenting intent.
6. `MindmapPreferences.Detail.init(rawValue: "banana")` returns `nil`; `flatMap` propagates the `nil`; `?? fallback.detail` then supplies `.balanced`. So a corrupt/unknown stored value safely becomes the default. (The line is `self.detail = defaults.string(...).flatMap(...) ?? fallback.detail`.)
7. `$viewModel.detail` is a `Binding<MindmapPreferences.Detail>`. The card needs a two‑way `Binding` (not a plain value) so that tapping a pill can write the new selection **back** to the view model; a plain value would be read‑only.
8. The default makes the parameter optional at the call site, so any existing caller (or test) that wrote `generateMindMap(from:)` still compiles — backward compatibility.
9. For `.concise`, `maxDepth` is `2`, so `2 >= 3` is `false` → empty string → "root → branches". For `.detailed`, `maxDepth` is `3` → "root → branches → leaves". It keeps the human‑readable hint in the prompt consistent with the actual depth number.
10. Change `MindmapPreferencesViewModel.submit` (or remove the `persist()` call) — and/or stop seeding from `UserDefaults` in `init`. The simplest: don't call `persist()`, and seed `init` straight from `MindmapPreferences.default`.
11. (a) **Delete** the unused `caption` properties — least code, but you lose the per‑option helper text. (b) **Re‑add** `caption` to the `PreferenceOption` protocol, give `Detail` one too, and render it under the pills — more UX, more code. Trade‑off: minimalism vs. guidance for the user.

---

*End of module.*
