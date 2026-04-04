import Foundation

enum AppLanguage: String, CaseIterable {
    case english  = "E"
    case romanian = "M"

    var displayName: String {
        switch self {
        case .english:  return "EN"
        case .romanian: return "RO"
        }
    }

    // Romanian month names (lowercase, as they appear in jw.org API titles)
    static let romanianMonthNames = [
        "ianuarie", "februarie", "martie", "aprilie", "mai", "iunie",
        "iulie", "august", "septembrie", "octombrie", "noiembrie", "decembrie"
    ]

    // MARK: - UI Strings

    var meetings: String    { self == .romanian ? "Ședințe"   : "Meetings" }
    var bible: String       { self == .romanian ? "Biblie"    : "Bible" }
    var songs: String       { self == .romanian ? "Cântări"   : "Songs" }
    var broadcasting: String { self == .romanian ? "Emisiuni" : "Broadcasting" }

    var weeklyMeetings: String  { self == .romanian ? "Ședințe Săptămânale"    : "Weekly Meetings" }
    var lastWeek: String        { self == .romanian ? "Săptămâna trecută"      : "Last Week" }
    var thisWeek: String        { self == .romanian ? "Această săptămână"      : "This Week" }
    var nextWeek: String        { self == .romanian ? "Săptămâna viitoare"     : "Next Week" }

    var meetingWorkbook: String        { self == .romanian ? "Caietul pentru întruniri" : "Meeting Workbook" }
    var watchtowerStudy: String        { self == .romanian ? "Studiul Turnul de Veghere" : "Watchtower Study" }
    var bibleReading: String           { self == .romanian ? "Lectura Bibliei"           : "Bible Reading" }
    var congregationBibleStudy: String { self == .romanian ? "Studiul Congregației"      : "Congregation Bible Study" }

    var hebrewScriptures: String { self == .romanian ? "Scripturile Ebraice"  : "Hebrew Scriptures" }
    var greekScriptures: String  { self == .romanian ? "Scripturile Grecești" : "Greek Scriptures" }
    var kingdomSongs: String     { self == .romanian ? "Cântări ale Împărăției" : "Kingdom Songs" }

    var chapter: String  { self == .romanian ? "Capitolul"  : "Chapter" }
    var chapters: String { self == .romanian ? "Capitolele" : "Chapters" }

    var loadingBible: String  { self == .romanian ? "Se încarcă Biblia…"    : "Loading Bible catalog…" }
    var loadingSongs: String  { self == .romanian ? "Se încarcă cântările…" : "Loading songs…" }
    var contentUnavailable: String { self == .romanian ? "Conținut indisponibil" : "Content not yet available" }
}

final class LanguageSettings: ObservableObject {
    static let shared = LanguageSettings()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: saved) {
            language = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? ""
            language = preferred.hasPrefix("ro") ? .romanian : .english
        }
    }
}
