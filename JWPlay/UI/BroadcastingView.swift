import SwiftUI

struct BroadcastingView: View {
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var langSettings: LanguageSettings
    @State private var tracks: [BroadcastingTrack] = []
    @State private var loading = true
    @State private var failed = false

    var body: some View {
        let lang = langSettings.language
        NavigationStack {
            Group {
                if loading {
                    ProgressView(lang.loadingBroadcasts)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if failed || tracks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tv.slash")
                            .font(.largeTitle).foregroundStyle(.secondary)
                        Text(lang.broadcastingUnavailable)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        // Bible Dramas folder — always at top
                        NavigationLink {
                            DramasListView()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "theatermasks.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.indigo, in: RoundedRectangle(cornerRadius: 8))
                                Text(lang.bibleDramas)
                                    .font(.body)
                                Spacer()
                            }
                        }

                        // Monthly programs + GB updates
                        ForEach(tracks) { track in
                            Button {
                                player.play(urls: [track.url], title: track.title,
                                            subtitle: track.subtitle, artwork: "tv.fill")
                            } label: {
                                HStack {
                                    Image(systemName: track.isGBUpdate ? "person.bust.fill" : "tv.fill")
                                        .foregroundStyle(track.isGBUpdate ? Color.purple : Color.blue)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title).lineLimit(2)
                                        if !track.subtitle.isEmpty {
                                            Text(track.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "play.circle")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(lang.broadcastingTitle)
            .task { await load() }
            .onChange(of: langSettings.language) { _ in
                tracks = []
                Task { await load() }
            }
        }
    }

    private func load() async {
        loading = true
        failed = false
        tracks = await JWAPIService.shared.fetchBroadcasting(language: langSettings.language)
        if tracks.isEmpty { failed = true }
        loading = false
    }
}

// MARK: - Bible Dramas list

struct DramasListView: View {
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var langSettings: LanguageSettings
    @State private var dramas: [BroadcastingTrack] = []
    @State private var loading = true

    var body: some View {
        let lang = langSettings.language
        Group {
            if loading {
                ProgressView(lang.loadingDramas)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dramas.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "theatermasks")
                        .font(.largeTitle).foregroundStyle(.secondary)
                    Text(lang.contentUnavailable)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(dramas) { drama in
                    Button {
                        player.play(urls: [drama.url], title: drama.title,
                                    subtitle: drama.subtitle, artwork: "theatermasks.fill")
                    } label: {
                        HStack {
                            Image(systemName: "theatermasks.fill")
                                .foregroundStyle(Color.indigo)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(drama.title).lineLimit(2)
                                if !drama.subtitle.isEmpty {
                                    Text(drama.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "play.circle")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(lang.bibleDramas)
        .task { await load() }
        .onChange(of: langSettings.language) { _ in
            dramas = []
            loading = true
            Task { await load() }
        }
    }

    private func load() async {
        loading = true
        dramas = await JWAPIService.shared.fetchDramas(language: langSettings.language)
        loading = false
    }
}
