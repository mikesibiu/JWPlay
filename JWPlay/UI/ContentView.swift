import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var player: AudioPlayer

    var body: some View {
        VStack(spacing: 0) {
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

            PlayerBar()
        }
    }
}
