import SwiftUI

struct SongsView: View {
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var langSettings: LanguageSettings
    @State private var songs: [PubMediaTrack] = []
    @State private var loading = true

    private let groupSize = 20

    private var groups: [[PubMediaTrack]] {
        stride(from: 0, to: songs.count, by: groupSize).map {
            Array(songs[$0..<min($0 + groupSize, songs.count)])
        }
    }

    var body: some View {
        let lang = langSettings.language
        NavigationStack {
            Group {
                if loading {
                    ProgressView(lang.loadingSongs)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groups.indices, id: \.self) { idx in
                            let start = idx * groupSize
                            NavigationLink {
                                SongGroupView(groupStart: start,
                                              groupSize: groupSize,
                                              allSongs: $songs)
                            } label: {
                                let group = groups[idx]
                                let first = group.first?.track ?? 0
                                let last  = group.last?.track  ?? 0
                                Text(String(format: "\(lang.songs) %03d–%03d", first, last))
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(lang.kingdomSongs)
            .task { await loadSongs() }
            .onChange(of: langSettings.language) { _ in
                songs = []
                loading = true
                Task { await loadSongs() }
            }
        }
    }

    private func loadSongs() async {
        guard songs.isEmpty else { return }
        if let tracks = await JWAPIService.shared.ensureSongs(language: langSettings.language) {
            songs = tracks.sorted { $0.track < $1.track }
        }
        loading = false
    }
}

struct SongGroupView: View {
    let groupStart: Int
    let groupSize: Int
    @Binding var allSongs: [PubMediaTrack]
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var langSettings: LanguageSettings

    private var songs: [PubMediaTrack] {
        guard groupStart < allSongs.count else { return [] }
        return Array(allSongs[groupStart..<min(groupStart + groupSize, allSongs.count)])
    }

    var body: some View {
        let lang = langSettings.language
        let first = songs.first?.track ?? 0
        let last  = songs.last?.track  ?? 0
        List {
            ForEach(songs, id: \.track) { song in
                Button {
                    guard let url = song.url else { return }
                    player.play(urls: [url],
                                title: song.title,
                                subtitle: String(format: "%03d", song.track),
                                artwork: "music.note")
                } label: {
                    HStack {
                        Text(String(format: "%03d", song.track))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .leading)
                        Text(song.title)
                        Spacer()
                        Image(systemName: "play.circle")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(songs.isEmpty ? "" : String(format: "\(lang.songs) %03d–%03d", first, last))
    }
}
