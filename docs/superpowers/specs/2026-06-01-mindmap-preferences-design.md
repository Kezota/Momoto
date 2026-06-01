# Mindmap Output Preferences — Design

**Date:** 2026-06-01
**Status:** Approved (pending spec review)
**Author:** Kenrich + Claude

## Summary

Add a preference card scene that appears **after the user provides input** (paste / PDF / scan / photo) and **before the mindmap is generated**. The card lets the user personalize the mindmap output along three dimensions. The selected preferences are injected into the AI prompt so the generated mindmap matches the user's intent.

## Goals

- Let users tune the mindmap output before generation: how detailed/large, how complex the wording, and what to optimize for.
- Make it low-friction: the card opens pre-filled with sensible defaults; a single tap generates.
- Remember the user's last-used preferences between sessions.
- Wire the feature into the existing flow in **one place** (the shared `processInput` chokepoint).

## Non-Goals

- No per-input-method preferences (one shared card for all four input types).
- No free-text preference input — fixed multiple-choice options only.
- No re-generation controls on the mindmap screen itself (out of scope for this change).
- No backend; generation continues to use the on-device `FoundationModels` `SystemLanguageModel`.

## The Three Preference Dimensions

| Dimension     | Options (raw)                          | Default     | What it controls |
|---------------|----------------------------------------|-------------|------------------|
| **Detail**    | `concise` · `balanced` · `detailed`    | `balanced`  | Summary richness **and** tree size/depth together (merged per user decision — a detailed map is also a bigger, deeper map). |
| **Complexity**| `simple` · `standard` · `technical`    | `standard`  | Vocabulary / wording register in titles and summaries. |
| **Focus**     | `study` · `overview` · `brainstorm`    | `overview`  | What the AI emphasizes when selecting and phrasing nodes. |

## Architecture (Approach A — dedicated scene)

A new full-screen route `AppRoute.preferences` is inserted between input and processing. This matches the app's existing one-route-per-step `NavigationStack` / `AppRoute` pattern. Because all four input methods already funnel through `HomeView.processInput(_:)`, the wiring change lives in a single place.

### Flow

```
[input view] --onSubmit/onText--> processInput(text)
    sets appState.pendingInputText
    pushes AppRoute.preferences            <-- CHANGED (was .processing)
        |
        v
[PreferencesView]  (loads remembered prefs via view model)
    user adjusts the three pill selectors (or leaves defaults)
    taps "Generate Mindmap"
        sets appState.pendingPreferences
        persists choices (@AppStorage)
        pushes AppRoute.processing
        |
        v
[ProcessingView]
    .task { generate(from: pendingInputText,
                     preferences: pendingPreferences,
                     source: "App") }
        |
        v
[ProcessingViewModel.generate] -> TextToNodeService.generateMindMap(from:preferences:)
        injects preference descriptors into the prompt
        |
        v
[MindMapView]
```

## Components

### 1. `Shared/Models/MindmapPreferences.swift` (new)

```swift
struct MindmapPreferences: Codable, Equatable {
    var detail: Detail
    var complexity: Complexity
    var focus: Focus

    static let `default` = MindmapPreferences(
        detail: .balanced, complexity: .standard, focus: .overview
    )

    enum Detail: String, CaseIterable, Codable {
        case concise, balanced, detailed
    }
    enum Complexity: String, CaseIterable, Codable {
        case simple, standard, technical
    }
    enum Focus: String, CaseIterable, Codable {
        case study, overview, brainstorm
    }
}
```

Each enum exposes:
- `label: String` — short text for the pill (e.g. "Concise", "Detailed").
- `promptDescriptor: String` — the instruction snippet injected into the AI prompt (see Prompt Mapping).

### 2. `AppRoute` (edit)

Add a case:
```swift
case preferences
```

### 3. `AppState` (edit, in `HomeView.swift`)

Add:
```swift
@Published var pendingPreferences: MindmapPreferences = .default
```
This mirrors the existing `pendingInputText` pattern so `ProcessingView` can read the chosen prefs without threading them through navigation values.

### 4. `HomeView` (edit)

- `processInput(_:)` pushes `.preferences` instead of `.processing`.
- Add a `navigationDestination` case for `.preferences` rendering `PreferencesView`, with a closure that sets `pendingPreferences` and pushes `.processing`.

### 5. `Features/MindmapPreferences/PreferencesView.swift` + `MindmapPreferencesViewModel.swift` (new)

**View:** follows the existing design system (`Theme`, rounded white card, `PrimaryButtonStyle`).
- Title: "Customize your mindmap" + one-line subtitle.
- One card containing **three labeled groups**, each:
  - a group label (e.g. "Detail"),
  - a segmented **pill selector** row of the enum's options,
  - a one-line caption describing the currently-selected option (or the dimension).
- Bottom: "Generate Mindmap" `PrimaryButtonStyle` button. Always enabled (defaults are valid), so a single tap proceeds.

**ViewModel** (`@MainActor`, `ObservableObject`):
- Holds the three selections, seeded from persistence.
- Persists via `@AppStorage` keys: `pref.detail`, `pref.complexity`, `pref.focus` (raw string values).
- On submit, builds a `MindmapPreferences` and calls the `onGenerate(MindmapPreferences)` closure.

A small reusable `PreferencePillRow` subview renders one selectable row generically over `[(label, isSelected, onTap)]`.

### 6. `Shared/Services/TextToNodeService.swift` (edit)

- `generateMindMap(from text: String, preferences: MindmapPreferences = .default)` — new parameter, **defaulted** so existing call sites and tests compile unchanged.
- `buildPrompt(for:preferences:)` — the currently-hardcoded structure rules become preference-driven (see Prompt Mapping).

### 7. `Features/Processing/ProcessingViewModel.swift` + `ProcessingView.swift` (edit)

- `generate(from:source:)` → `generate(from:preferences:source:)`.
- `ProcessingView.task` and the "Try Again" button pass `appState.pendingPreferences`.

## Prompt Mapping

`buildPrompt` keeps its current JSON/output/symbol rules. The **structure**, **content wording**, and **focus** rules become derived from preferences.

**Detail → structure rules:**

| Detail     | Max depth | Root children | Summary word cap |
|------------|-----------|---------------|------------------|
| `concise`  | 2         | 2–3           | ≤ 10 words       |
| `balanced` | 3         | 3–5           | ≤ 15 words       |
| `detailed` | 3         | 4–6 (richer leaves) | ≤ 22 words |

**Complexity → wording line:**
- `simple` → "Use simple, everyday language a beginner understands. Avoid jargon."
- `standard` → "Use clear, neutral language."
- `technical` → "Use precise technical/domain terminology where appropriate."

**Focus → emphasis line:**
- `study` → "Optimize for memorization: short memorable titles and key facts, definitions, and cause/effect."
- `overview` → "Optimize for a high-level overview: the most important themes and how they relate."
- `brainstorm` → "Optimize for idea generation: include related and adjacent concepts and possibilities."

These three snippets are produced by the enums' `promptDescriptor` and concatenated into the prompt's rule sections. The word cap / depth / child-count numbers come from `Detail` (encapsulated in `Detail.promptDescriptor` or a small struct of numeric params owned by `Detail`).

## Persistence

`@AppStorage` (UserDefaults) holds the three raw enum string values. The view model seeds its selections from them on init and writes them on submit. No migration concerns (new keys; absent → defaults).

## Error Handling

Unchanged. `ProcessingView` already renders `.failure(message)` with a "Try Again" button; that retry now re-passes the same `pendingPreferences`. Invalid/absent persisted values fall back to defaults via the enum's failable init guard (`?? .default`-style seeding).

## Testing

- **`MindmapPreferences` Codable round-trip** — encode/decode returns an equal value.
- **`promptDescriptor` per case** — each enum case returns its expected snippet/params (table-driven).
- **`buildPrompt` injection** — for representative preference combos, the prompt string contains the expected depth/word-cap/wording/focus snippets (e.g. `concise` ⇒ contains "Maximum depth: 2"; `simple` ⇒ contains "beginner"). `buildPrompt` may be made `internal` (or a testable helper extracted) to allow assertion.
- **Default fallback** — seeding the view model with an unknown stored raw value yields `.default` for that dimension.

(No UI snapshot tests; the app has no existing test target convention beyond unit-level logic — keep tests to pure logic.)

## File Change Summary

**New:**
- `Momoto/Shared/Models/MindmapPreferences.swift`
- `Momoto/Features/MindmapPreferences/PreferencesView.swift`
- `Momoto/Features/MindmapPreferences/MindmapPreferencesViewModel.swift`

**Edited:**
- `Momoto/App/AppRoute.swift` (+`case preferences`)
- `Momoto/Features/Home/HomeView.swift` (`AppState.pendingPreferences`, `processInput` push target, new `navigationDestination` case)
- `Momoto/Shared/Services/TextToNodeService.swift` (`preferences` param + prompt mapping)
- `Momoto/Features/Processing/ProcessingViewModel.swift` (`generate` signature)
- `Momoto/Features/Processing/ProcessingView.swift` (pass `pendingPreferences`)

The Xcode project uses file-system-synchronized groups (Xcode 16), so new files under `Momoto/` are auto-included — no `project.pbxproj` edits required.
