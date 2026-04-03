import SwiftUI

struct ContentView: View {
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
            PlayerBar()
        }
    }
}
