# JW Auto — CarPlay & iPhone Audio App

An iOS app that brings jw.org audio content to Apple CarPlay and iPhone. Built as a companion to the Android Auto JW Library implementation — same content, same API, native iOS interface.

## What It Does

Plays all jw.org public audio content:

| Tab | Content |
|-----|---------|
| **Meetings** | Weekly Meeting Workbook, Watchtower Study, Bible Reading, Congregation Bible Study — for last, current, and next week |
| **Bible** | Full NWT Bible (all 66 books, all chapters) with chapter-to-end-of-book queuing |
| **Songs** | All Kingdom Songs (sjjc vocal version) |
| **Broadcasting** | JW Broadcasting monthly programs + Governing Body Updates |

Mini player bar above the tab bar shows current track with skip back / play-pause / skip forward controls. Full lock screen and remote control support via `MPNowPlayingInfoCenter`.

## Technical Stack

- **SwiftUI** — all UI (iOS 16+)
- **CarPlay** — `CPTemplateApplicationSceneDelegate`, `CPListTemplate`, `CPNowPlayingTemplate`
- **AVQueuePlayer** — gapless playlist playback
- **MPRemoteCommandCenter** — lock screen / CarPlay controls
- jw.org public APIs — no authentication required
  - `pub-media` API (`b.jw-cdn.org/apis/pub-media/GETPUBMEDIALINKS`) for MWB, Watchtower, NWT, Songs, LFB
  - Mediator API (`b.jw-cdn.org/apis/mediator/v1`) for Broadcasting
  - WOL (`wol.jw.org`) HTML parsing for CBS lesson numbers and Bible chapter range

## Project Structure

```
JWPlay/
├── project.yml              # xcodegen config
└── JWPlay/
    ├── App/
    │   ├── JWPlayApp.swift  # @main SwiftUI entry point
    │   └── AppDelegate.swift
    ├── CarPlay/
    │   ├── CarPlaySceneDelegate.swift
    │   └── CarPlayTemplateProvider.swift
    ├── Models/
    │   ├── WeeklySchedule.swift   # Week date math, MWB/WT track matching
    │   ├── BibleBook.swift        # All 66 books with chapter counts
    │   └── PubMediaResponse.swift # API response models
    ├── Services/
    │   ├── JWAPIService.swift     # All network fetches (actor)
    │   ├── AudioPlayer.swift      # AVQueuePlayer singleton (@MainActor)
    │   ├── CacheService.swift     # UserDefaults cache with version invalidation
    │   └── WOLParser.swift        # HTML parsing for CBS/Bible range
    ├── UI/
    │   ├── ContentView.swift      # TabView root
    │   ├── PlayerBar.swift        # Mini player bar
    │   ├── MeetingsView.swift     # Weekly meetings + content rows
    │   ├── BibleView.swift        # Bible book/chapter browser
    │   ├── SongsView.swift        # Kingdom Songs browser
    │   └── BroadcastingView.swift # JW Broadcasting
    └── Assets.xcassets/           # App icon (1024x1024)
```

## Building

Requires [xcodegen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
cd JWPlay
xcodegen generate
open JWPlay.xcodeproj
```

Build and run on an iPhone simulator or device. Requires an Apple Developer account (free or paid) for device installation.

## Key Implementation Notes

- **MWB track matching** — track titles use the Monday of the meeting week (e.g. "April 6-12"). Issue code uses odd months only (April → March issue).
- **Watchtower matching** — track titles embed Monday date in parens: `"(March 30 - April 5)"`. Issues tried at offsets -1, -2, -3 months.
- **CBS/Bible Reading** — fetched from WOL (`wol.jw.org/en/wol/d/r1/lp-e/{docid}`) using the MWB docid. Requires MWB fetch to succeed first.
- **Empty schedule caching** — schedules with no content are not written to cache, preventing stale poisoning on API failures.
- **Cache invalidation** — bump `CacheService.currentVersion` to force a full cache clear on next launch.

## Distribution

Currently distributed via TestFlight. Requires Apple Developer Program ($99/year).
