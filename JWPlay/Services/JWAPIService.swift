import Foundation

actor JWAPIService {
    static let shared = JWAPIService()
    private init() {}

    private let session = URLSession.shared
    private let baseURL       = "https://b.jw-cdn.org/apis/pub-media/GETPUBMEDIALINKS"
    private let mediatorBase  = "https://b.jw-cdn.org/apis/mediator/v1"
    private let wolBase       = "https://wol.jw.org/en/wol/d/r1/lp-e"

    // In-memory caches for the session
    private var nwtTracks: [PubMediaTrack]?
    private var lfbTracks: [PubMediaTrack]?
    private var songsTracks: [PubMediaTrack]?

    // MARK: - Public API

    func buildWeeklySchedule(for weekDate: WeekDate) async -> WeeklySchedule {
        // Fetch MWB first — WOL needs its docid, so they cannot be parallel.
        // Watchtower, NWT, and LFB are independent and run concurrently.
        let mwb = await fetchMWBTrack(weekDate: weekDate)

        async let wolResult = fetchWOLSchedule(docid: mwb?.docid)
        async let wtResult  = fetchWatchtowerTrack(weekDate: weekDate)
        async let nwtResult = ensureNWT()
        async let lfbResult = ensureLFB()

        let (wol, wt, nwtAll, lfbAll) = await (wolResult, wtResult, nwtResult, lfbResult)

        // Bible reading URLs
        var bibleURLs: [URL] = []
        var bibleTitle = "Bible Reading"
        if let range = wol?.bibleRange, let nwt = nwtAll {
            let chapters = nwt
                .filter { $0.booknum == range.booknum &&
                           $0.track >= range.startChapter &&
                           $0.track <= range.endChapter }
                .sorted { $0.track < $1.track }
                .compactMap { $0.url }
            bibleURLs = chapters
            if let book = BibleBook.byBooknum[range.booknum] {
                bibleTitle = "\(book.name) \(range.startChapter)–\(range.endChapter)"
            }
        }

        // CBS URLs — lesson numbers from WOL, then look up in LFB catalog
        // Match by leading digit(s) in title ("68. Title") — mirrors Android LfbLessonCatalog
        var cbsURLs: [URL] = []
        var cbsTitle = "Congregation Bible Study"
        if let lessonNums = wol?.cbsLessons, !lessonNums.isEmpty, let lfb = lfbAll {
            cbsURLs = lessonNums.compactMap { num in
                lfb.first { track in
                    lfbLeadingNumber(track) == num
                }?.url
            }
            if let first = lessonNums.first, let last = lessonNums.last {
                cbsTitle = first == last ? "CBS Lesson \(first)" : "CBS Lessons \(first)–\(last)"
            }
        }

        return WeeklySchedule(
            weekKey: weekDate.isoKey,
            weekLabel: weekDate.displayLabel,
            mwbURL: mwb?.url,
            mwbTitle: mwb?.title ?? "Meeting Workbook",
            watchtowerURL: wt?.url,
            watchtowerTitle: wt?.title ?? "Watchtower Study",
            bibleReadingURLs: bibleURLs,
            bibleReadingTitle: bibleTitle,
            cbsURLs: cbsURLs,
            cbsTitle: cbsTitle,
            mwbDocid: mwb?.docid
        )
    }

    func ensureNWT() async -> [PubMediaTrack]? {
        if let cached = nwtTracks { return cached }
        if let disk = CacheService.shared.cachedNWT() { nwtTracks = disk; return disk }
        guard let tracks = try? await fetchTracks(pub: "nwt", issue: "0") else { return nil }
        nwtTracks = tracks
        CacheService.shared.cacheNWT(tracks)
        return tracks
    }

    func ensureLFB() async -> [PubMediaTrack]? {
        if let cached = lfbTracks { return cached }
        if let disk = CacheService.shared.cachedLFB() { lfbTracks = disk; return disk }
        guard let tracks = try? await fetchTracks(pub: "lfb", issue: nil) else { return nil }
        lfbTracks = tracks
        CacheService.shared.cacheLFB(tracks)
        return tracks
    }

    func ensureSongs() async -> [PubMediaTrack]? {
        if let cached = songsTracks { return cached }
        if let disk = CacheService.shared.cachedSongs() { songsTracks = disk; return disk }
        // sjjc = vocal/congregation version (matches Android Auto); sjjm = male vocals only
        guard let tracks = try? await fetchTracks(pub: "sjjc", issue: nil) else { return nil }
        songsTracks = tracks
        CacheService.shared.cacheSongs(tracks)
        return tracks
    }

    func fetchBroadcasting() async -> [BroadcastingTrack] {
        // Mediator API: GET /categories/E/{category}?detailed=1
        // Categories confirmed from Android Auto implementation:
        //   StudioMonthlyPrograms  — monthly JW Broadcasting programs
        //   StudioNewsReports      — Governing Body updates
        async let monthly   = fetchMediatorCategory("StudioMonthlyPrograms",  isGB: false)
        async let gbUpdates = fetchMediatorCategory("StudioNewsReports",       isGB: true)
        let (mon, gbu) = await (monthly, gbUpdates)

        return Array((gbu + mon).prefix(30))
    }

    // MARK: - Private fetches

    private func fetchMWBTrack(weekDate: WeekDate) async -> PubMediaTrack? {
        guard let tracks = try? await fetchTracks(pub: "mwb", issue: weekDate.mwbIssue) else { return nil }
        return tracks
            .sorted { $0.track < $1.track }
            .first { weekDate.mwbTrackMatches(title: $0.title) }
    }

    private struct WOLSchedule {
        let bibleRange: WOLParser.BibleRange?
        let cbsLessons: [Int]
    }

    private func fetchWOLSchedule(docid: Int?) async -> WOLSchedule? {
        guard let docid else { return nil }
        let urlString = "\(wolBase)/\(docid)"
        guard let url = URL(string: urlString),
              let (data, _) = try? await session.data(from: url),
              let html = String(data: data, encoding: .utf8) else { return nil }

        let lessons   = WOLParser.parseCBSLessons(from: html)
        let bibleRange = WOLParser.parseBibleRange(from: html)
        return WOLSchedule(bibleRange: bibleRange, cbsLessons: lessons)
    }

    private func fetchWatchtowerTrack(weekDate: WeekDate) async -> PubMediaTrack? {
        for issue in weekDate.watchtowerIssuesToTry {
            guard let tracks = try? await fetchTracks(pub: "w", issue: issue) else { continue }
            if let match = tracks.sorted(by: { $0.track < $1.track })
                                 .first(where: { weekDate.watchtowerTrackMatches(title: $0.title) }) {
                return match
            }
        }
        return nil
    }

    private func fetchTracks(pub: String, issue: String?) async throws -> [PubMediaTrack] {
        var components = URLComponents(string: baseURL)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "output",      value: "json"),
            URLQueryItem(name: "pub",         value: pub),
            URLQueryItem(name: "fileformat",  value: "MP3"),
            URLQueryItem(name: "alllangs",    value: "0"),
            URLQueryItem(name: "langwritten", value: "E"),
            URLQueryItem(name: "txtCMSLang",  value: "E"),
        ]
        if let issue = issue {
            items.append(URLQueryItem(name: "issue", value: issue))
        }
        components.queryItems = items

        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(PubMediaResponse.self, from: data)
        return response.files.E?.MP3 ?? []
    }

    /// Extracts the leading lesson number from an LFB track title, e.g. "68 Title" → 68.
    /// Mirrors Android's LfbLessonCatalog: Regex("^(\\d{1,3})").find(title)
    private func lfbLeadingNumber(_ track: PubMediaTrack) -> Int? {
        let text = track.title.isEmpty ? (track.label ?? "") : track.title
        var digits = ""
        for ch in text.prefix(4) {
            if ch.isNumber { digits.append(ch) } else { break }
        }
        return digits.isEmpty ? nil : Int(digits)
    }

    private func fetchMediatorCategory(_ category: String, isGB: Bool) async -> [BroadcastingTrack] {
        let urlString = "\(mediatorBase)/categories/E/\(category)?detailed=1"
        guard let url = URL(string: urlString),
              let (data, _) = try? await session.data(from: url) else { return [] }
        guard let response = try? JSONDecoder().decode(MediatorCategoryResponse.self, from: data) else { return [] }

        let cutoff = Date().addingTimeInterval(-365 * 24 * 3600)
        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .none
            return f
        }()

        return response.items()
            .filter { item in
                guard let date = item.publishedDate else { return true }
                return date > cutoff
            }
            .sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
            .compactMap { item -> BroadcastingTrack? in
                guard let audioURL = item.firstAudioURL else { return nil }
                let id = "broadcast-\(category)-\(item.guid ?? item.naturalKey ?? UUID().uuidString)"
                let subtitle = item.publishedDate.map { dateFormatter.string(from: $0) } ?? ""
                return BroadcastingTrack(
                    id: id,
                    title: item.title ?? (isGB ? "Governing Body Update" : "JW Broadcasting"),
                    subtitle: subtitle,
                    url: audioURL,
                    isGBUpdate: isGB
                )
            }
    }
}
