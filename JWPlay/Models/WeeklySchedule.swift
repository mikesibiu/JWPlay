import Foundation

struct WeeklySchedule: Codable {
    let weekKey: String          // ISO week key e.g. "2026-W14"
    let weekLabel: String        // e.g. "March 30 – April 5"
    let mwbURL: URL?
    let mwbTitle: String
    let watchtowerURL: URL?
    let watchtowerTitle: String
    let bibleReadingURLs: [URL]  // playlist — 1 to 3 chapters
    let bibleReadingTitle: String
    let cbsURLs: [URL]           // playlist — typically 2 lessons
    let cbsTitle: String
    let mwbDocid: Int?           // for wol.jw.org lookup
}

extension WeeklySchedule {
    var hasMWB: Bool { mwbURL != nil }
    var hasWatchtower: Bool { watchtowerURL != nil }
    var hasBibleReading: Bool { !bibleReadingURLs.isEmpty }
    var hasCBS: Bool { !cbsURLs.isEmpty }
    var hasAnyContent: Bool { hasMWB || hasWatchtower || hasBibleReading || hasCBS }
}

// MARK: - Week offset helpers

enum WeekOffset: Int, CaseIterable {
    case last = -1
    case current = 0
    case next = 1

    var label: String {
        switch self {
        case .last:    return "Last Week"
        case .current: return "This Week"
        case .next:    return "Next Week"
        }
    }
}

struct WeekDate {
    let monday: Date

    init(offset: WeekOffset = .current, from base: Date = Date()) {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2  // Monday-first (ISO)
        let thisMonday = cal.date(
            from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base)
        ) ?? base
        monday = cal.date(byAdding: .weekOfYear, value: offset.rawValue, to: thisMonday) ?? thisMonday
    }

    // ISO week key e.g. "2026-W14"
    var isoKey: String {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4  // ISO 8601
        let year = cal.component(.yearForWeekOfYear, from: monday)
        let week = cal.component(.weekOfYear, from: monday)
        return String(format: "%04d-W%02d", year, week)
    }

    // MWB issue code: odd month → use it; even month → use month-1
    var mwbIssue: String {
        let cal = Calendar(identifier: .gregorian)
        let month = cal.component(.month, from: monday)
        let year  = cal.component(.year,  from: monday)
        let issueMonth = month % 2 == 0 ? month - 1 : month
        return String(format: "%04d%02d", year, issueMonth)
    }

    // Watchtower issues to try: current month -1, -2, -3
    var watchtowerIssuesToTry: [String] {
        let cal = Calendar(identifier: .gregorian)
        return [1, 2, 3].map { offset in
            let adjusted = cal.date(byAdding: .month, value: -offset, to: monday) ?? monday
            let year  = cal.component(.year,  from: adjusted)
            let month = cal.component(.month, from: adjusted)
            return String(format: "%04d%02d", year, month)
        }
    }

    // Monday's day-of-month and English month name — used by WT/MWB matching
    var dayOfMonth: Int {
        Calendar(identifier: .gregorian).component(.day, from: monday)
    }

    var monthName: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US")
        fmt.dateFormat = "MMMM"
        return fmt.string(from: monday)
    }

    // Romanian month name for Monday's month
    var romanianMonthName: String {
        let month = Calendar(identifier: .gregorian).component(.month, from: monday)
        return AppLanguage.romanianMonthNames[month - 1]
    }

    // Display label "March 30 – April 5"
    var displayLabel: String {
        let cal = Calendar(identifier: .gregorian)
        let sunday = cal.date(byAdding: .day, value: 6, to: monday) ?? monday
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US")
        let startMonth = cal.component(.month, from: monday)
        let endMonth   = cal.component(.month, from: sunday)
        if startMonth == endMonth {
            fmt.dateFormat = "MMMM d"
            let start = fmt.string(from: monday)
            fmt.dateFormat = "d"
            return "\(start)–\(fmt.string(from: sunday))"
        } else {
            fmt.dateFormat = "MMMM d"
            return "\(fmt.string(from: monday)) – \(fmt.string(from: sunday))"
        }
    }

    // Does a MWB track title match this week?
    // MWB track titles use Monday's date (e.g. "April 6-12" for week of Monday April 6)
    func mwbTrackMatches(title: String) -> Bool {
        title.hasPrefix("\(monthName) \(dayOfMonth)")
    }

    // Does a Watchtower track title match this week?
    // English: "...Speak the Truth Graciously (March 30 - April 5)" → \\(March 30[^0-9]
    // Romanian: "...Cum ne putem... (6-12 aprilie)" → \\(6[^0-9].*aprilie
    func watchtowerTrackMatches(title: String, language: AppLanguage) -> Bool {
        switch language {
        case .english:
            let pattern = "\\(\(monthName) \(dayOfMonth)[^0-9]"
            return title.range(of: pattern, options: .regularExpression) != nil
        case .romanian:
            let pattern = "\\(\(dayOfMonth)[^0-9].*\(romanianMonthName)"
            return title.range(of: pattern, options: .regularExpression) != nil
        }
    }
}
