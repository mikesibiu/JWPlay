import SwiftUI

struct BroadcastingView: View {
    @EnvironmentObject private var player: AudioPlayer
    @State private var tracks: [BroadcastingTrack] = []
    @State private var loading = true
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Loading broadcasts…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if failed || tracks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tv.slash")
                            .font(.largeTitle).foregroundStyle(.secondary)
                        Text("JW Broadcasting content could not be loaded.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(tracks) { track in
                        Button {
                            player.play(urls: [track.url], title: track.title,
                                        subtitle: track.subtitle, artwork: "tv.fill")
                        } label: {
                            HStack {
                                Image(systemName: track.isGBUpdate ? "person.bust.fill" : "tv.fill")
                                    .foregroundStyle(track.isGBUpdate ? .purple : .blue)
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
                                    .foregroundStyle(.accent)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("JW Broadcasting")
            .task { await load() }
        }
    }

    private func load() async {
        loading = true
        failed = false
        tracks = await JWAPIService.shared.fetchBroadcasting()
        if tracks.isEmpty { failed = true }
        loading = false
    }
}
