import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var player: AudioPlayer

    var body: some View {
        TabView {
            MeetingsView()
                .tabItem { Label("Meetings", systemImage: "calendar") }

            BibleView()
                .tabItem { Label("Bible", systemImage: "text.book.closed.fill") }

            SongsView()
                .tabItem { Label("Songs", systemImage: "music.note") }

            BroadcastingView()
                .tabItem { Label("Broadcasting", systemImage: "tv") }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Only inset when something is playing — avoids empty space at bottom
            if !player.currentTitle.isEmpty {
                PlayerBar()
            }
        }
    }
}
