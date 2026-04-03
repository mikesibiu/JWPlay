import CarPlay
import UIKit

@MainActor
final class CarPlayTemplateProvider {
    private weak var interfaceController: CPInterfaceController?
    private let player = AudioPlayer.shared
    private let api = JWAPIService.shared
    private let songGroupSize = 20
    private let chapterGroupSize = BibleBook.chapterGroupSize

    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
    }

    // MARK: - Root

    func connect() {
        let root = makeRootTemplate()
        interfaceController?.setRootTemplate(root, animated: false, completion: nil)
    }

    private func makeRootTemplate() -> CPListTemplate {
        let meetingsItem = makeBrowsableItem("Weekly Meetings", detail: "This, last & next week", systemImage: "calendar")
        let bibleItem    = makeBrowsableItem("Bible & Songs", detail: "All 66 books + Kingdom Songs", systemImage: "book")

        meetingsItem.handler = { [weak self] _, done in
            Task { @MainActor in await self?.showMeetings(); done() }
        }
        bibleItem.handler = { [weak self] _, done in
            Task { @MainActor in self?.showBibleAndSongs(); done() }
        }

        let section = CPListSection(items: [meetingsItem, bibleItem])
        return CPListTemplate(title: "JW Library", sections: [section])
    }

    // MARK: - Weekly Meetings

    private func showMeetings() async {
        let items = WeekOffset.allCases.map { offset -> CPListItem in
            let weekDate = WeekDate(offset: offset)
            let item = makeBrowsableItem(offset.label, detail: weekDate.displayLabel)
            item.handler = { [weak self] _, done in
                Task { @MainActor in await self?.showWeekContent(weekDate: weekDate); done() }
            }
            return item
        }
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Weekly Meetings", sections: [section])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    private func showWeekContent(weekDate: WeekDate) async {
        // Show a loading state first
        let loadingItem = CPListItem(text: "Loading…", detailText: weekDate.displayLabel)
        let loadingTemplate = CPListTemplate(title: weekDate.displayLabel,
                                             sections: [CPListSection(items: [loadingItem])])
        interfaceController?.pushTemplate(loadingTemplate, animated: true, completion: nil)

        // Check cache first
        let schedule: WeeklySchedule
        if let cached = CacheService.shared.cachedSchedule(for: weekDate.isoKey) {
            schedule = cached
        } else {
            schedule = await api.buildWeeklySchedule(for: weekDate)
            CacheService.shared.cache(schedule: schedule, for: weekDate.isoKey)
        }

        var items: [CPListItem] = []

        if let url = schedule.mwbURL {
            let item = makePlayableItem(schedule.mwbTitle, detail: "Meeting Workbook")
            item.handler = { [weak self] _, done in
                Task { @MainActor in
                    self?.player.play(urls: [url], title: schedule.mwbTitle,
                                      subtitle: weekDate.displayLabel, artwork: "book.fill")
                    self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared,
                                                           animated: true, completion: nil)
                    done()
                }
            }
            items.append(item)
        }

        if let url = schedule.watchtowerURL {
            let item = makePlayableItem(schedule.watchtowerTitle, detail: "Watchtower Study")
            item.handler = { [weak self] _, done in
                Task { @MainActor in
                    self?.player.play(urls: [url], title: schedule.watchtowerTitle,
                                      subtitle: weekDate.displayLabel, artwork: "book.fill")
                    self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared,
                                                           animated: true, completion: nil)
                    done()
                }
            }
            items.append(item)
        }

        if !schedule.bibleReadingURLs.isEmpty {
            let item = makePlayableItem(schedule.bibleReadingTitle, detail: "Bible Reading")
            let urls = schedule.bibleReadingURLs
            item.handler = { [weak self] _, done in
                Task { @MainActor in
                    self?.player.play(urls: urls, title: schedule.bibleReadingTitle,
                                      subtitle: weekDate.displayLabel, artwork: "text.book.closed.fill")
                    self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared,
                                                           animated: true, completion: nil)
                    done()
                }
            }
            items.append(item)
        }

        if !schedule.cbsURLs.isEmpty {
            let item = makePlayableItem(schedule.cbsTitle, detail: "Congregation Bible Study")
            let urls = schedule.cbsURLs
            item.handler = { [weak self] _, done in
                Task { @MainActor in
                    self?.player.play(urls: urls, title: schedule.cbsTitle,
                                      subtitle: weekDate.displayLabel, artwork: "person.3.fill")
                    self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared,
                                                           animated: true, completion: nil)
                    done()
                }
            }
            items.append(item)
        }

        if items.isEmpty {
            let empty = CPListItem(text: "Content unavailable", detailText: "Check connection")
            items = [empty]
        }

        let section = CPListSection(items: items)
        let template = CPListTemplate(title: weekDate.displayLabel, sections: [section])

        // Wait for pop to complete before pushing — avoids template stack race condition
        guard let ic = interfaceController else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ic.popTemplate(animated: false) { _, _ in continuation.resume() }
        }
        ic.pushTemplate(template, animated: true, completion: nil)
    }

    // MARK: - Bible & Songs

    private func showBibleAndSongs() {
        let hebrewItem = makeBrowsableItem("Hebrew Scriptures", detail: "Genesis – Malachi")
        let greekItem  = makeBrowsableItem("Greek Scriptures", detail: "Matthew – Revelation")
        let songsItem  = makeBrowsableItem("Kingdom Songs", detail: "160+ songs")

        hebrewItem.handler = { [weak self] _, done in
            self?.showBookList(books: BibleBook.hebrewScriptures, title: "Hebrew Scriptures")
            done()
        }
        greekItem.handler = { [weak self] _, done in
            self?.showBookList(books: BibleBook.greekScriptures, title: "Greek Scriptures")
            done()
        }
        songsItem.handler = { [weak self] _, done in
            Task { @MainActor in await self?.showSongGroups(); done() }
        }

        let section = CPListSection(items: [hebrewItem, greekItem, songsItem])
        let template = CPListTemplate(title: "Bible & Songs", sections: [section])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    // MARK: - Bible books

    private func showBookList(books: [BibleBook], title: String) {
        let items = books.map { book -> CPListItem in
            let item = makeBrowsableItem(book.abbreviation, detail: book.name)
            item.handler = { [weak self] _, done in
                Task { @MainActor in await self?.showBook(book); done() }
            }
            return item
        }
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: title, sections: [section])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    private func showBook(_ book: BibleBook) async {
        guard let nwt = await api.ensureNWT() else { return }
        let chapters = nwt
            .filter { $0.booknum == book.id }
            .sorted { $0.track < $1.track }
        let allURLs = chapters.compactMap { $0.url }

        if book.needsChapterGroups {
            showChapterGroups(book: book, chapters: chapters, allURLs: allURLs)
        } else {
            showChapterList(book: book, chapters: chapters, allURLs: allURLs, groupOffset: 0)
        }
    }

    private func showChapterGroups(book: BibleBook, chapters: [PubMediaTrack], allURLs: [URL]) {
        let groups = stride(from: 0, to: chapters.count, by: chapterGroupSize).map { start -> CPListItem in
            let end = min(start + chapterGroupSize - 1, chapters.count - 1)
            let startCh = chapters[start].track
            let endCh   = chapters[end].track
            let item = makeBrowsableItem("Chapters \(startCh)–\(endCh)", detail: book.name)
            item.handler = { [weak self] _, done in
                self?.showChapterList(book: book,
                                      chapters: Array(chapters[start...end]),
                                      allURLs: allURLs,
                                      groupOffset: start)
                done()
            }
            return item
        }
        let section = CPListSection(items: groups)
        let template = CPListTemplate(title: book.name, sections: [section])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    private func showChapterList(book: BibleBook, chapters: [PubMediaTrack], allURLs: [URL], groupOffset: Int) {
        let items = chapters.enumerated().map { (localIdx, ch) -> CPListItem in
            let globalIdx = groupOffset + localIdx
            let item = makePlayableItem("Chapter \(ch.track)", detail: book.name)
            item.handler = { [weak self] _, done in
                Task { @MainActor in
                    // Playlist from tapped chapter to end of book
                    let playlistURLs = Array(allURLs.dropFirst(globalIdx))
                    self?.player.play(urls: playlistURLs,
                                      title: "\(book.name) \(ch.track)",
                                      subtitle: book.name,
                                      artwork: "text.book.closed.fill")
                    self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared,
                                                           animated: true, completion: nil)
                    done()
                }
            }
            return item
        }
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: book.name, sections: [section])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    // MARK: - Kingdom Songs

    private func showSongGroups() async {
        guard let songs = await api.ensureSongs() else { return }
        let sorted = songs.sorted { $0.track < $1.track }

        let groups = stride(from: 0, to: sorted.count, by: songGroupSize).map { start -> CPListItem in
            let end = min(start + songGroupSize - 1, sorted.count - 1)
            let startNum = sorted[start].track
            let endNum   = sorted[end].track
            let label = String(format: "Songs %03d–%03d", startNum, endNum)
            let item = makeBrowsableItem(label, detail: nil)
            item.handler = { [weak self] _, done in
                self?.showSongList(Array(sorted[start...end]))
                done()
            }
            return item
        }
        let section = CPListSection(items: groups)
        let template = CPListTemplate(title: "Kingdom Songs", sections: [section])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    private func showSongList(_ songs: [PubMediaTrack]) {
        let items = songs.compactMap { song -> CPListItem? in
            guard let url = song.url else { return nil }
            let numStr = String(format: "%03d", song.track)
            let title  = "\(numStr) - \(song.title)"
            let item   = makePlayableItem(title, detail: nil)
            item.handler = { [weak self] _, done in
                Task { @MainActor in
                    self?.player.play(urls: [url], title: song.title,
                                      subtitle: "Kingdom Song \(song.track)", artwork: "music.note")
                    self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared,
                                                           animated: true, completion: nil)
                    done()
                }
            }
            return item
        }
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Kingdom Songs", sections: [section])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    // MARK: - Item factory helpers

    private func makeBrowsableItem(_ text: String, detail: String?, systemImage: String? = nil) -> CPListItem {
        let item = CPListItem(text: text, detailText: detail)
        item.accessoryType = .disclosureIndicator
        if let name = systemImage,
           let image = UIImage(systemName: name)?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            item.setImage(image)
        }
        return item
    }

    private func makePlayableItem(_ text: String, detail: String?) -> CPListItem {
        CPListItem(text: text, detailText: detail)
    }
}
