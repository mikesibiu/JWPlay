import SwiftUI

struct PlayerBar: View {
    @EnvironmentObject private var player: AudioPlayer

    var body: some View {
        if !player.currentTitle.isEmpty {
            HStack(spacing: 12) {
                Image(systemName: player.currentArtwork)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentTitle)
                        .font(.subheadline).bold()
                        .lineLimit(1)
                    Text(player.currentSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 16) {
                    Button { player.skipBackward() } label: {
                        Image(systemName: "backward.fill")
                    }
                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                    }
                    Button { player.skipForward() } label: {
                        Image(systemName: "forward.fill")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(duration: 0.3), value: player.currentTitle)
        }
    }
}
