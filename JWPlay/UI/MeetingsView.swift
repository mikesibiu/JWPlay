import SwiftUI

struct MeetingsView: View {
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var langSettings: LanguageSettings
    @State private var schedules: [WeekOffset: WeeklySchedule] = [:]
    @State private var loading: Set<WeekOffset> = []
    @State private var selected: WeekOffset = .current

    var body: some View {
        let lang = langSettings.language
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Week", selection: $selected) {
                    ForEach(WeekOffset.allCases, id: \.self) { offset in
                        Text(offset.label(for: lang)).tag(offset)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if loading.contains(selected) {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let schedule = schedules[selected] {
                    WeekContentView(schedule: schedule)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle).foregroundStyle(.secondary)
                        Text(lang.contentUnavailable)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(lang.weeklyMeetings)
            .task(id: selected) { await loadSchedule(for: selected) }
            .task(id: langSettings.language) {
                schedules = [:]
                await loadSchedule(for: selected)
            }
        }
    }

    private func loadSchedule(for offset: WeekOffset) async {
        guard schedules[offset] == nil else { return }
        loading.insert(offset)
        defer { loading.remove(offset) }

        let weekDate = WeekDate(offset: offset)
        let lang = langSettings.language
        if let cached = CacheService.shared.cachedSchedule(for: weekDate.isoKey, language: lang) {
            schedules[offset] = cached
            return
        }
        let schedule = await JWAPIService.shared.buildWeeklySchedule(for: weekDate, language: lang)
        if schedule.hasAnyContent {
            CacheService.shared.cache(schedule: schedule, for: weekDate.isoKey, language: lang)
        }
        schedules[offset] = schedule
    }
}

// MARK: - Week content rows

struct WeekContentView: View {
    let schedule: WeeklySchedule
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var langSettings: LanguageSettings

    var body: some View {
        let lang = langSettings.language
        List {
            Section(schedule.weekLabel) {
                if let url = schedule.mwbURL {
                    ContentRow(title: schedule.mwbTitle,
                               subtitle: lang.meetingWorkbook,
                               icon: "book.fill", color: .orange) {
                        player.play(urls: [url], title: schedule.mwbTitle,
                                    subtitle: schedule.weekLabel, artwork: "book.fill")
                    }
                }
                if let url = schedule.watchtowerURL {
                    ContentRow(title: schedule.watchtowerTitle,
                               subtitle: lang.watchtowerStudy,
                               icon: "book.closed.fill", color: .blue) {
                        player.play(urls: [url], title: schedule.watchtowerTitle,
                                    subtitle: schedule.weekLabel, artwork: "book.closed.fill")
                    }
                }
                if !schedule.bibleReadingURLs.isEmpty {
                    ContentRow(title: schedule.bibleReadingTitle,
                               subtitle: lang.bibleReading,
                               icon: "text.book.closed.fill", color: .green) {
                        player.play(urls: schedule.bibleReadingURLs,
                                    title: schedule.bibleReadingTitle,
                                    subtitle: schedule.weekLabel, artwork: "text.book.closed.fill")
                    }
                }
                if !schedule.cbsURLs.isEmpty {
                    ContentRow(title: schedule.cbsTitle,
                               subtitle: lang.congregationBibleStudy,
                               icon: "person.3.fill", color: .purple) {
                        player.play(urls: schedule.cbsURLs,
                                    title: schedule.cbsTitle,
                                    subtitle: schedule.weekLabel, artwork: "person.3.fill")
                    }
                }
                if !schedule.hasMWB && !schedule.hasWatchtower &&
                   !schedule.hasBibleReading && !schedule.hasCBS {
                    Label(lang.contentUnavailable, systemImage: "clock")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct ContentRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(color, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(subtitle).font(.subheadline).bold().foregroundStyle(.primary)
                    Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(.plain)
    }
}
