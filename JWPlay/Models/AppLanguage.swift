import Foundation

enum AppLanguage: String, CaseIterable {
    case english  = "E"
    case french   = "F"
    case romanian = "M"

    var displayName: String {
        switch self {
        case .english:  return "EN"
        case .french:   return "FR"
        case .romanian: return "RO"
        }
    }

    // Month names (lowercase) as they appear in jw.org API titles
    static let romanianMonthNames = [
        "ianuarie", "februarie", "martie", "aprilie", "mai", "iunie",
        "iulie", "august", "septembrie", "octombrie", "noiembrie", "decembrie"
    ]
    static let frenchMonthNames = [
        "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    ]

    // MARK: - UI Strings

    var meetings: String {
        switch self {
        case .english:  return "Meetings"
        case .french:   return "Réunions"
        case .romanian: return "Ședințe"
        }
    }
    var bible: String {
        switch self {
        case .english:  return "Bible"
        case .french:   return "Bible"
        case .romanian: return "Biblie"
        }
    }
    var songs: String {
        switch self {
        case .english:  return "Songs"
        case .french:   return "Cantiques"
        case .romanian: return "Cântări"
        }
    }
    var broadcasting: String {
        switch self {
        case .english:  return "Broadcasting"
        case .french:   return "Émissions"
        case .romanian: return "Emisiuni"
        }
    }

    var weeklyMeetings: String {
        switch self {
        case .english:  return "Weekly Meetings"
        case .french:   return "Réunions de la semaine"
        case .romanian: return "Ședințe Săptămânale"
        }
    }
    var lastWeek: String {
        switch self {
        case .english:  return "Last Week"
        case .french:   return "Semaine dernière"
        case .romanian: return "Săptămâna trecută"
        }
    }
    var thisWeek: String {
        switch self {
        case .english:  return "This Week"
        case .french:   return "Cette semaine"
        case .romanian: return "Această săptămână"
        }
    }
    var nextWeek: String {
        switch self {
        case .english:  return "Next Week"
        case .french:   return "Semaine prochaine"
        case .romanian: return "Săptămâna viitoare"
        }
    }

    var meetingWorkbook: String {
        switch self {
        case .english:  return "Meeting Workbook"
        case .french:   return "Cahier des réunions"
        case .romanian: return "Caietul pentru întruniri"
        }
    }
    var watchtowerStudy: String {
        switch self {
        case .english:  return "Watchtower Study"
        case .french:   return "Étude de La Tour de Garde"
        case .romanian: return "Studiul Turnul de Veghere"
        }
    }
    var bibleReading: String {
        switch self {
        case .english:  return "Bible Reading"
        case .french:   return "Lecture de la Bible"
        case .romanian: return "Lectura Bibliei"
        }
    }
    var congregationBibleStudy: String {
        switch self {
        case .english:  return "Congregation Bible Study"
        case .french:   return "Étude de la congrégation"
        case .romanian: return "Studiul Congregației"
        }
    }

    var hebrewScriptures: String {
        switch self {
        case .english:  return "Hebrew Scriptures"
        case .french:   return "Écritures hébraïques"
        case .romanian: return "Scripturile Ebraice"
        }
    }
    var greekScriptures: String {
        switch self {
        case .english:  return "Greek Scriptures"
        case .french:   return "Écritures grecques"
        case .romanian: return "Scripturile Grecești"
        }
    }
    var kingdomSongs: String {
        switch self {
        case .english:  return "Kingdom Songs"
        case .french:   return "Cantiques du Royaume"
        case .romanian: return "Cântări ale Împărăției"
        }
    }

    var chapter: String {
        switch self {
        case .english:  return "Chapter"
        case .french:   return "Chapitre"
        case .romanian: return "Capitolul"
        }
    }
    var chapters: String {
        switch self {
        case .english:  return "Chapters"
        case .french:   return "Chapitres"
        case .romanian: return "Capitolele"
        }
    }

    var loadingMeetings: String {
        switch self {
        case .english:  return "Loading meetings…"
        case .french:   return "Chargement des réunions…"
        case .romanian: return "Se încarcă ședințele…"
        }
    }
    var loadingBible: String {
        switch self {
        case .english:  return "Loading Bible catalog…"
        case .french:   return "Chargement de la Bible…"
        case .romanian: return "Se încarcă Biblia…"
        }
    }
    var loadingSongs: String {
        switch self {
        case .english:  return "Loading songs…"
        case .french:   return "Chargement des cantiques…"
        case .romanian: return "Se încarcă cântările…"
        }
    }
    var loadingBroadcasts: String {
        switch self {
        case .english:  return "Loading broadcasts…"
        case .french:   return "Chargement des émissions…"
        case .romanian: return "Se încarcă emisiunile…"
        }
    }
    var loadingDramas: String {
        switch self {
        case .english:  return "Loading dramas…"
        case .french:   return "Chargement des pièces…"
        case .romanian: return "Se încarcă dramele…"
        }
    }
    var contentUnavailable: String {
        switch self {
        case .english:  return "Content not yet available"
        case .french:   return "Contenu indisponible"
        case .romanian: return "Conținut indisponibil"
        }
    }
    var broadcastingUnavailable: String {
        switch self {
        case .english:  return "JW Broadcasting content could not be loaded."
        case .french:   return "Le contenu JW Émissions n'a pas pu être chargé."
        case .romanian: return "Conținutul emisiunilor nu a putut fi încărcat."
        }
    }
    var broadcastingTitle: String {
        switch self {
        case .english:  return "JW Broadcasting"
        case .french:   return "JW Émissions"
        case .romanian: return "Emisiuni JW"
        }
    }
    var bibleDramas: String {
        switch self {
        case .english:  return "Bible Dramas"
        case .french:   return "Drames bibliques"
        case .romanian: return "Drame Biblice"
        }
    }
    var governingBodyUpdate: String {
        switch self {
        case .english:  return "Governing Body Update"
        case .french:   return "Mise à jour du Collège central"
        case .romanian: return "Noutăți de la Corpul Guvernant"
        }
    }
    var loading: String {
        switch self {
        case .english:  return "Loading…"
        case .french:   return "Chargement…"
        case .romanian: return "Se încarcă…"
        }
    }
    var bibleAndSongs: String {
        switch self {
        case .english:  return "Bible & Songs"
        case .french:   return "Bible et Cantiques"
        case .romanian: return "Biblie și Cântări"
        }
    }
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
            if preferred.hasPrefix("fr") { language = .french }
            else if preferred.hasPrefix("ro") { language = .romanian }
            else { language = .english }
        }
    }
}
