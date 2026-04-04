import Foundation

// MARK: - jw.org pub-media API response types

struct PubMediaResponse: Codable {
    let files: LanguageMap
}

// Decodes a dynamic language key (e.g. "E" or "M") from the files dictionary
struct LanguageMap: Codable {
    private var storage: [String: FormatMap] = [:]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        storage = (try? container.decode([String: FormatMap].self)) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }

    subscript(lang: String) -> FormatMap? { storage[lang] }
}

struct FormatMap: Codable {
    let MP3: [PubMediaTrack]?
}

struct PubMediaTrack: Codable {
    let title: String
    let file: FileInfo
    let track: Int
    let docid: Int?
    let booknum: Int?
    let label: String?
    let pub: String?
    let issue: String?

    var url: URL? { URL(string: file.url) }
}

struct FileInfo: Codable {
    let url: String
    let checksum: String?
    let modifiedDatetime: String?
}

// MARK: - Mediator API response (used for JW Broadcasting)
// Base URL: https://b.jw-cdn.org/apis/mediator/v1/
// Endpoint:  GET categories/{language}/{category}?detailed=1
// Categories: StudioMonthlyPrograms, StudioNewsReports (GB updates)

struct MediatorCategoryResponse: Codable {
    let category: MediatorCategory?

    func items() -> [MediatorMediaItem] { category?.media ?? [] }
}

struct MediatorCategory: Codable {
    let key: String?
    let name: String?
    let media: [MediatorMediaItem]?
}

struct MediatorMediaItem: Codable {
    let guid: String?
    let naturalKey: String?
    let title: String?
    let firstPublished: String?        // ISO 8601 e.g. "2025-11-22T00:00:00.000Z"
    let durationSeconds: Double?
    let files: [MediatorMediaFile]?

    enum CodingKeys: String, CodingKey {
        case guid, naturalKey, title, firstPublished
        case durationSeconds = "duration"
        case files
    }

    /// Prefer "240p" label (smallest video, audio-only playback) — mirrors Android PREFERRED_VIDEO_QUALITY.
    /// Falls back to first available file URL.
    var firstAudioURL: URL? {
        let preferred = files?.first { $0.label == "240p" }?.url
            ?? files?.first { $0.url != nil }?.url
        return preferred.flatMap { URL(string: $0) }
    }

    var publishedDate: Date? {
        guard let s = firstPublished else { return nil }
        return ISO8601DateFormatter().date(from: s)
    }
}

struct MediatorMediaFile: Codable {
    let label: String?
    let mimeType: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case label
        case mimeType = "mimetype"
        case url = "progressiveDownloadURL"
    }
}

// MARK: - Broadcasting display model

struct BroadcastingTrack: Identifiable {
    let id: String
    let title: String
    let subtitle: String          // formatted publish date
    let url: URL
    let isGBUpdate: Bool
}
