# Romanian Language Support — Lessons Learned

---

## Romanian Language Code

Romanian on jw.org uses the code **`M`** (not `RO`, `ROM`, or `ROL`).

Found by inspecting network requests on `https://www.jw.org/ro/library/magazines/` — the API calls include `langwritten=M`.

---

## What Content Is Available in Romanian

**Available:**
- Watchtower Study — `pub=w, lang=M`
- NWT Bible — `pub=nwt, lang=M` (1,189 tracks)
- Kingdom Songs — `pub=sjjc, lang=M` (53 tracks)
- LFB / CBS book — `pub=lfb, lang=M` (118 tracks)

**Not available:**
- Meeting Workbook — `pub=mwb` returns 404 for `lang=M`. jw.org only publishes MWB as text/PDF in Romanian, no audio recording.
- JW Broadcasting — Mediator API categories only have English content.

---

## Watchtower Title Date Format

English and Romanian WT titles use **reversed date formats**.

English:
```
Speak the Truth Graciously (March 30 - April 5)
```

Romanian:
```
Cum ne putem ajuta rudele care nu sunt Martore? (6-12 aprilie)
```

English puts month first, then day. Romanian puts day first, then month (lowercase).

This required separate regex patterns in `watchtowerTrackMatches(title:language:)`:

```swift
// English — month then day
let pattern = "\\(\(monthName) \(dayOfMonth)[^0-9]"

// Romanian — day then month
let pattern = "\\(\(dayOfMonth)[^0-9].*\(romanianMonthName)"
```

Romanian month names as they appear in API titles (all lowercase):
> ianuarie, februarie, martie, aprilie, mai, iunie, iulie, august, septembrie, octombrie, noiembrie, decembrie

---

## WOL Parsing Strategy

Romanian WOL exists at `/ro/wol/d/r34/lp-m/{docid}` but uses different text markers
(e.g. "Studiu de Congregație" instead of "Congregation Bible Study"), which would require
a Romanian version of `WOLParser`.

**Decision: always use the English WOL for parsing.** CBS lesson numbers and Bible chapter
ranges are identical across languages. Fetch English WOL → get lesson numbers and chapter
range → look up Romanian audio files (LFB, NWT) using those same numbers.

This avoids maintaining a translated WOLParser and is more robust against future text changes.

---

## Meeting Workbook — Romanian Workaround

Since Romanian MWB audio doesn't exist on the API, we still fetch the **English MWB** to
get the `docid` needed for WOL parsing (which gives CBS lessons and Bible chapter range).

The MWB audio row is simply hidden in the UI for Romanian users. Everything else — Watchtower
Study, Bible Reading, and CBS — still works because those audio files exist in Romanian.

---

## PubMediaResponse Model Fix

The original `LanguageMap` model was hardcoded with a single `let E: FormatMap?` property.
It had to be replaced with a dynamic dictionary decoder to support any language code:

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

## Cache Keys Must Include Language

All caches (schedule, NWT, LFB, Songs) must be keyed by language code to prevent
cross-language collisions:

- English schedule: `schedule_2026-W14_E`
- Romanian schedule: `schedule_2026-W14_M`

---

## Device Language Detection

iOS device language is read from `Locale.preferredLanguages.first`.
Romanian locale strings start with `"ro"` (e.g. `"ro-RO"`, `"ro"`).

```swift
let preferred = Locale.preferredLanguages.first ?? ""
language = preferred.hasPrefix("ro") ? .romanian : .english
```

The detected language is saved to `UserDefaults` so it persists across launches.
The user can also override it manually with the EN/RO toggle in the app.

---

## CarPlay

CarPlay reads `LanguageSettings.shared.language` directly (it has no SwiftUI environment).
All API calls in `CarPlayTemplateProvider` must pass the language explicitly — it is not
injected automatically like in SwiftUI views.
