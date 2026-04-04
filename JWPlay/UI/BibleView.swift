import SwiftUI

struct BibleView: View {
    @EnvironmentObject private var langSettings: LanguageSettings
    @State private var nwtTracks: [PubMediaTrack] = []
    @State private var loading = true
    @State private var testament: BibleBook.Testament = .hebrew

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Testament", selection: $testament) {
                    Text("Hebrew Scriptures").tag(BibleBook.Testament.hebrew)
                    Text("Greek Scriptures").tag(BibleBook.Testament.greek)
                }
                .pickerStyle(.segmented)
                .padding()

                if loading {
                    ProgressView("Loading Bible catalog…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    bookList
                }
            }
            .navigationTitle("Bible")
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

    private var bookList: some View {
        List(books) { book in
            NavigationLink {
                BookChaptersView(book: book, allTracks: nwtTracks)
            } label: {
                HStack {
                    Text(book.abbreviation)
                        .font(.body).bold()
                        .frame(width: 44, alignment: .leading)
                    Text(book.name)
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
    let allTracks: [PubMediaTrack]
    @EnvironmentObject private var player: AudioPlayer

    private var bookTracks: [PubMediaTrack] {
        allTracks.filter { $0.booknum == book.id }.sorted { $0.track < $1.track }
    }
    private var bookURLs: [URL] { bookTracks.compactMap { $0.url } }

    var body: some View {
        Group {
            if book.needsChapterGroups {
                groupedList
            } else {
                chapterList(tracks: bookTracks, globalOffset: 0)
            }
        }
        .navigationTitle(book.name)
    }

    private var groupedList: some View {
        let groups = stride(from: 0, to: bookTracks.count, by: BibleBook.chapterGroupSize)
            .map { start -> (Int, Int) in
                let end = min(start + BibleBook.chapterGroupSize - 1, bookTracks.count - 1)
                return (start, end)
            }
        return List {
            ForEach(groups, id: \.0) { start, end in
                let startCh = bookTracks[start].track
                let endCh   = bookTracks[end].track
                NavigationLink("Chapters \(startCh)–\(endCh)") {
                    chapterList(tracks: Array(bookTracks[start...end]), globalOffset: start)
                        .navigationTitle("Chapters \(startCh)–\(endCh)")
                }
            }
        }
    }

    @ViewBuilder
    private func chapterList(tracks: [PubMediaTrack], globalOffset: Int) -> some View {
        List(tracks.indices, id: \.self) { localIdx in
            let track = tracks[localIdx]
            let globalIdx = globalOffset + localIdx
            Button {
                let playlistURLs = Array(bookURLs.dropFirst(globalIdx))
                player.play(urls: playlistURLs,
                            title: "\(book.name) \(track.track)",
                            subtitle: book.name,
                            artwork: "text.book.closed.fill")
            } label: {
                HStack {
                    Text("Chapter \(track.track)")
                    Spacer()
                    Image(systemName: "play.circle")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
