import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var player: AudioPlayer

    var body: some View {
        TabView {
            MeetingsView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !player.currentTitle.isEmpty { PlayerBar() }
                }
                .tabItem { Label("Meetings", systemImage: "calendar") }

            BibleView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !player.currentTitle.isEmpty { PlayerBar() }
                }
                .tabItem { Label("Bible", systemImage: "text.book.closed.fill") }

            SongsView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !player.currentTitle.isEmpty { PlayerBar() }
                }
                .tabItem { Label("Songs", systemImage: "music.note") }

            BroadcastingView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !player.currentTitle.isEmpty { PlayerBar() }
                }
                .tabItem { Label("Broadcasting", systemImage: "tv") }
        }
    }
}
