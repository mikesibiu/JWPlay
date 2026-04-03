import Foundation

final class CacheService {
    static let shared = CacheService()
    private let defaults = UserDefaults.standard
    private init() {}

    private enum Key {
        static func weeklySchedule(_ isoKey: String) -> String { "schedule_\(isoKey)" }
        static func nwtTracks() -> String { "nwt_tracks" }
        static func lfbTracks() -> String { "lfb_tracks" }
        static func songsTracks() -> String { "songs_tracks" }
        static let cacheVersion = "cache_version"
    }

    private let currentVersion = 1

    // Call at app launch — clears all content if version bumped
    func clearIfVersionChanged() {
        let saved = defaults.integer(forKey: Key.cacheVersion)
        if saved != currentVersion {
            clearAll()
            defaults.set(currentVersion, forKey: Key.cacheVersion)
        }
    }

    func clearAll() {
        let keys = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("schedule_") || $0 == Key.nwtTracks() ||
            $0 == Key.lfbTracks() || $0 == Key.songsTracks()
        }
        keys.forEach { defaults.removeObject(forKey: $0) }
    }

    // MARK: - Weekly schedule

    func cachedSchedule(for isoKey: String) -> WeeklySchedule? {
        guard let data = defaults.data(forKey: Key.weeklySchedule(isoKey)) else { return nil }
        return try? JSONDecoder().decode(WeeklySchedule.self, from: data)
    }

    func cache(schedule: WeeklySchedule, for isoKey: String) {
        if let data = try? JSONEncoder().encode(schedule) {
            defaults.set(data, forKey: Key.weeklySchedule(isoKey))
        }
    }

    // MARK: - Catalog caches (NWT, LFB, Songs)

    func cachedNWT() -> [PubMediaTrack]? { decodeTracks(forKey: Key.nwtTracks()) }
    func cacheNWT(_ tracks: [PubMediaTrack]) { encodeTracks(tracks, forKey: Key.nwtTracks()) }

    func cachedLFB() -> [PubMediaTrack]? { decodeTracks(forKey: Key.lfbTracks()) }
    func cacheLFB(_ tracks: [PubMediaTrack]) { encodeTracks(tracks, forKey: Key.lfbTracks()) }

    func cachedSongs() -> [PubMediaTrack]? { decodeTracks(forKey: Key.songsTracks()) }
    func cacheSongs(_ tracks: [PubMediaTrack]) { encodeTracks(tracks, forKey: Key.songsTracks()) }

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
