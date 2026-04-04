# Romanian Language Support — Lessons Learned

## Language Code

Romanian on jw.org uses the language code **`M`** (not `RO`, `ROM`, or `ROL`).

Discovered by inspecting the network requests on `https://www.jw.org/ro/library/magazines/` which reveals `langwritten=M` in API calls.

---

## Content Availability

| Content | Available in Romanian | Notes |
|---------|----------------------|-------|
| Watchtower Study | YES | pub=w, lang=M |
| NWT Bible | YES | pub=nwt, lang=M, 1189 tracks |
| Kingdom Songs | YES | pub=sjjc, lang=M, 53 tracks |
| LFB / CBS book | YES | pub=lfb, lang=M, 118 tracks |
| Meeting Workbook | **NO** | pub=mwb returns 404 for lang=M — jw.org only publishes MWB as text/PDF in Romanian, no audio |
| JW Broadcasting | NO | Mediator API categories only have English content |

---

## Watchtower Title Format Difference

English and Romanian WT track titles have **reversed date formats**:

- **English:** `"Speak the Truth Graciously (March 30 - April 5)"` — Month Day format
- **Romanian:** `"Cum ne putem ajuta rudele... (6-12 aprilie)"` — Day Month format, month lowercase

This required separate regex patterns:

```swift
// English
let pattern = "\\(\(monthName) \(dayOfMonth)[^0-9]"

// Romanian
let pattern = "\\(\(dayOfMonth)[^0-9].*\(romanianMonthName)"
```

Romanian month names (lowercase as they appear in API): `ianuarie, februarie, martie, aprilie, mai, iunie, iulie, august, septembrie, octombrie, noiembrie, decembrie`

---

## WOL Parsing Strategy

Romanian WOL exists at `/ro/wol/d/r34/lp-m/{docid}` but the HTML structure uses different
Romanian text markers (e.g. "Studiu de Congregație" instead of "Congregation Bible Study").

**Decision: always use English WOL for parsing.** CBS lesson numbers and Bible chapter ranges
are universal across languages. Fetch English WOL → get lesson numbers → look up Romanian LFB audio.
This avoids maintaining a Romanian WOLParser and is more robust.

---

## MWB Handling for Romanian

Since Romanian MWB audio doesn't exist, we still fetch the **English MWB** to get the `docid`
needed for WOL parsing (which gives us CBS lessons + Bible chapter range).

The `mwbURL` is set to `nil` for Romanian so the MWB row doesn't appear in the UI.
Everything else (WT, Bible Reading, CBS) still works because those audio files exist in Romanian.

---

## PubMediaResponse Model

The original `LanguageMap` model was hardcoded with a single `let E: FormatMap?` property.
This had to be replaced with a dynamic dictionary decoder to support arbitrary language codes:

```swift
struct LanguageMap: Codable {
    private var storage: [String: FormatMap] = [:]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        storage = (try? container.decode([String: FormatMap].self)) ?? [:]
    }

    subscript(lang: String) -> FormatMap? { storage[lang] }
}
```

---

## Cache Keys

All caches (schedule, NWT, LFB, Songs) must be keyed by language code to prevent
cross-language cache collisions. Format: `schedule_2026-W14_E` vs `schedule_2026-W14_M`.

---

## Language Detection

iOS device language is detected via `Locale.preferredLanguages.first`.
Romanian locale strings start with `"ro"` (e.g. `"ro-RO"`, `"ro"`).

```swift
let preferred = Locale.preferredLanguages.first ?? ""
language = preferred.hasPrefix("ro") ? .romanian : .english
```

---

## UI Toggle

A compact `EN | RO` segmented control lives at the top of `ContentView`, above the `TabView`.
Changing language clears in-memory state in `MeetingsView`, `BibleView`, and `SongsView`
via `.onChange(of: langSettings.language)` and triggers a fresh fetch.

`LanguageSettings` is a `@Published` `ObservableObject` singleton injected as an
`.environmentObject` from `JWPlayApp`.
