import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var langSettings: LanguageSettings

    var body: some View {
        VStack(spacing: 0) {
            // Language toggle bar
            HStack {
                Spacer()
                Picker("Language", selection: $langSettings.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .background(Color(uiColor: .systemBackground))
            .overlay(alignment: .bottom) { Divider() }

            let lang = langSettings.language
            TabView {
                MeetingsView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if !player.currentTitle.isEmpty { PlayerBar() }
                    }
                    .tabItem { Label(lang.meetings, systemImage: "calendar") }

                BibleView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if !player.currentTitle.isEmpty { PlayerBar() }
                    }
                    .tabItem { Label(lang.bible, systemImage: "text.book.closed.fill") }

                SongsView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if !player.currentTitle.isEmpty { PlayerBar() }
                    }
                    .tabItem { Label(lang.songs, systemImage: "music.note") }

                BroadcastingView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if !player.currentTitle.isEmpty { PlayerBar() }
                    }
                    .tabItem { Label(lang.broadcasting, systemImage: "tv") }
            }
        }
    }
}
