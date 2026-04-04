import SwiftUI

struct SongsView: View {
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var langSettings: LanguageSettings
    @State private var songs: [PubMediaTrack] = []
    @State private var loading = true
    @State private var navPath = NavigationPath()

    private let groupSize = 20

    private var groups: [[PubMediaTrack]] {
        stride(from: 0, to: songs.count, by: groupSize).map {
            Array(songs[$0..<min($0 + groupSize, songs.count)])
        }
    }

    var body: some View {
        let lang = langSettings.language
        NavigationStack(path: $navPath) {
            Group {
                if loading {
                    ProgressView(lang.loadingSongs)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groups.indices, id: \.self) { idx in
                            let group = groups[idx]
                            let first = group.first?.track ?? 0
                            let last  = group.last?.track  ?? 0
                            let label = String(format: "\(lang.songs) %03d–%03d", first, last)
                            NavigationLink(label) {
                                SongGroupView(songs: group)
                                    .navigationTitle(label)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(lang.kingdomSongs)
            .task { await loadSongs() }
            .onChange(of: langSettings.language) { _ in
                navPath = NavigationPath()
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
    let songs: [PubMediaTrack]
    @EnvironmentObject private var player: AudioPlayer

    var body: some View {
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
    }
}
