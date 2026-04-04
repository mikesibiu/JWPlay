import Foundation

final class CacheService {
    static let shared = CacheService()
    private let defaults = UserDefaults.standard
    private init() {}

    private enum Key {
        static func weeklySchedule(_ isoKey: String, _ lang: String) -> String { "schedule_\(isoKey)_\(lang)" }
        static func nwtTracks(_ lang: String)  -> String { "nwt_tracks_\(lang)" }
        static func lfbTracks(_ lang: String)  -> String { "lfb_tracks_\(lang)" }
        static func songsTracks(_ lang: String) -> String { "songs_tracks_\(lang)" }
        static let cacheVersion = "cache_version"
    }

    private let currentVersion = 4

    func clearIfVersionChanged() {
        let saved = defaults.integer(forKey: Key.cacheVersion)
        if saved != currentVersion {
            clearAll()
            defaults.set(currentVersion, forKey: Key.cacheVersion)
        }
    }

    func clearAll() {
        let keys = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("schedule_") || $0.hasPrefix("nwt_tracks") ||
            $0.hasPrefix("lfb_tracks") || $0.hasPrefix("songs_tracks")
        }
        keys.forEach { defaults.removeObject(forKey: $0) }
    }

    // MARK: - Weekly schedule (language-keyed)

    func cachedSchedule(for isoKey: String, language: AppLanguage) -> WeeklySchedule? {
        guard let data = defaults.data(forKey: Key.weeklySchedule(isoKey, language.rawValue)) else { return nil }
        return try? JSONDecoder().decode(WeeklySchedule.self, from: data)
    }

    func cache(schedule: WeeklySchedule, for isoKey: String, language: AppLanguage) {
        if let data = try? JSONEncoder().encode(schedule) {
            defaults.set(data, forKey: Key.weeklySchedule(isoKey, language.rawValue))
        }
    }

    // MARK: - Catalog caches (language-keyed)

    func cachedNWT(language: AppLanguage) -> [PubMediaTrack]? { decodeTracks(forKey: Key.nwtTracks(language.rawValue)) }
    func cacheNWT(_ tracks: [PubMediaTrack], language: AppLanguage) { encodeTracks(tracks, forKey: Key.nwtTracks(language.rawValue)) }

    func cachedLFB(language: AppLanguage) -> [PubMediaTrack]? { decodeTracks(forKey: Key.lfbTracks(language.rawValue)) }
    func cacheLFB(_ tracks: [PubMediaTrack], language: AppLanguage) { encodeTracks(tracks, forKey: Key.lfbTracks(language.rawValue)) }

    func cachedSongs(language: AppLanguage) -> [PubMediaTrack]? { decodeTracks(forKey: Key.songsTracks(language.rawValue)) }
    func cacheSongs(_ tracks: [PubMediaTrack], language: AppLanguage) { encodeTracks(tracks, forKey: Key.songsTracks(language.rawValue)) }

    private func decodeTracks(forKey key: String) -> [PubMediaTrack]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([PubMediaTrack].self, from: data)
    }

    private func encodeTracks(_ tracks: [PubMediaTrack], forKey key: String) {
        if let data = try? JSONEncoder().encode(tracks) {
            defaults.set(data, forKey: key)
        }
    }
}
