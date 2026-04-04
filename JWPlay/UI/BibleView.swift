import SwiftUI

struct BibleView: View {
    @EnvironmentObject private var langSettings: LanguageSettings
    @State private var nwtTracks: [PubMediaTrack] = []
    @State private var loading = true
    @State private var testament: BibleBook.Testament = .hebrew

    var body: some View {
        let lang = langSettings.language
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Testament", selection: $testament) {
                    Text(lang.hebrewScriptures).tag(BibleBook.Testament.hebrew)
                    Text(lang.greekScriptures).tag(BibleBook.Testament.greek)
                }
                .pickerStyle(.segmented)
                .padding()

                if loading {
                    ProgressView(lang.loadingBible)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    bookList
                }
            }
            .navigationTitle(lang.bible)
            .task { await loadNWT() }
            .onChange(of: langSettings.language) { _ in
                nwtTracks = []
                loading = true
                Task { await loadNWT() }
            }
        }
    }

    private var books: [BibleBook] {
        testament == .hebrew ? BibleBook.hebrewScriptures : BibleBook.greekScriptures
    }

    // Extract Romanian book name from NWT track title e.g. "Geneza - Capitolul 1" → "Geneza"
    private func displayName(for book: BibleBook) -> String {
        guard langSettings.language == .romanian else { return book.name }
        if let track = nwtTracks.first(where: { $0.booknum == book.id }),
           let roName = track.title.components(separatedBy: " - ").first {
            return roName
        }
        return book.name
    }

    private var bookList: some View {
        List(books) { book in
            NavigationLink {
                BookChaptersView(book: book, allTracks: $nwtTracks)
            } label: {
                HStack {
                    Text(book.abbreviation)
                        .font(.body).bold()
                        .frame(width: 44, alignment: .leading)
                    Text(displayName(for: book))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(book.chapterCount) ch")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .listStyle(.plain)
    }

    private func loadNWT() async {
        guard nwtTracks.isEmpty else { return }
        if let tracks = await JWAPIService.shared.ensureNWT(language: langSettings.language) {
            nwtTracks = tracks
        }
        loading = false
    }
}

// MARK: - Chapter groups / direct chapter list

struct BookChaptersView: View {
    let book: BibleBook
    @Binding var allTracks: [PubMediaTrack]
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var langSettings: LanguageSettings

    private var bookTracks: [PubMediaTrack] {
        allTracks.filter { $0.booknum == book.id }.sorted { $0.track < $1.track }
    }
    private var bookURLs: [URL] { bookTracks.compactMap { $0.url } }

    // Romanian book name from first track title
    private var displayName: String {
        guard langSettings.language == .romanian else { return book.name }
        if let track = bookTracks.first,
           let roName = track.title.components(separatedBy: " - ").first {
            return roName
        }
        return book.name
    }

    var body: some View {
        let lang = langSettings.language
        Group {
            if book.needsChapterGroups {
                groupedList(lang: lang)
            } else {
                chapterList(tracks: bookTracks, globalOffset: 0, lang: lang)
            }
        }
        .navigationTitle(displayName)
    }

    private func groupedList(lang: AppLanguage) -> some View {
        let groups = stride(from: 0, to: bookTracks.count, by: BibleBook.chapterGroupSize)
            .map { start -> (Int, Int) in
                let end = min(start + BibleBook.chapterGroupSize - 1, bookTracks.count - 1)
                return (start, end)
            }
        return List {
            ForEach(groups, id: \.0) { start, end in
                let startCh = bookTracks[start].track
                let endCh   = bookTracks[end].track
                NavigationLink("\(lang.chapters) \(startCh)–\(endCh)") {
                    chapterList(tracks: Array(bookTracks[start...end]), globalOffset: start, lang: lang)
                        .navigationTitle("\(lang.chapters) \(startCh)–\(endCh)")
                }
            }
        }
    }

    @ViewBuilder
    private func chapterList(tracks: [PubMediaTrack], globalOffset: Int, lang: AppLanguage) -> some View {
        List(tracks.indices, id: \.self) { localIdx in
            let track = tracks[localIdx]
            let globalIdx = globalOffset + localIdx
            Button {
                let playlistURLs = Array(bookURLs.dropFirst(globalIdx))
                player.play(urls: playlistURLs,
                            title: "\(displayName) \(track.track)",
                            subtitle: displayName,
                            artwork: "text.book.closed.fill")
            } label: {
                HStack {
                    Text("\(lang.chapter) \(track.track)")
                    Spacer()
                    Image(systemName: "play.circle")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
