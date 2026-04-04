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
            // Auto-detect: Romanian if device language starts with "ro"
            let preferred = Locale.preferredLanguages.first ?? ""
            language = preferred.hasPrefix("ro") ? .romanian : .english
        }
    }
}
