import SwiftUI

struct MeetingsView: View {
    @EnvironmentObject private var player: AudioPlayer
    @State private var schedules: [WeekOffset: WeeklySchedule] = [:]
    @State private var loading: Set<WeekOffset> = []
    @State private var selected: WeekOffset = .current

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Week", selection: $selected) {
                    ForEach(WeekOffset.allCases, id: \.self) { Text($0.label).tag($0) }
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
                        Text("Unable to load meeting content")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Weekly Meetings")
            .task(id: selected) { await loadSchedule(for: selected) }
        }
    }

    private func loadSchedule(for offset: WeekOffset) async {
        guard schedules[offset] == nil else { return }
        loading.insert(offset)
        defer { loading.remove(offset) }

        let weekDate = WeekDate(offset: offset)
        if let cached = CacheService.shared.cachedSchedule(for: weekDate.isoKey) {
            schedules[offset] = cached
            return
        }
        let schedule = await JWAPIService.shared.buildWeeklySchedule(for: weekDate)
        if schedule.hasAnyContent {
            CacheService.shared.cache(schedule: schedule, for: weekDate.isoKey)
        }
        schedules[offset] = schedule
    }
}

// MARK: - Week content rows

struct WeekContentView: View {
    let schedule: WeeklySchedule
    @EnvironmentObject private var player: AudioPlayer

    var body: some View {
        List {
            Section(schedule.weekLabel) {
                if let url = schedule.mwbURL {
                    ContentRow(title: schedule.mwbTitle,
                               subtitle: "Meeting Workbook",
                               icon: "book.fill",
                               color: .orange) {
                        player.play(urls: [url], title: schedule.mwbTitle,
                                    subtitle: schedule.weekLabel, artwork: "book.fill")
                    }
                }
                if let url = schedule.watchtowerURL {
                    ContentRow(title: schedule.watchtowerTitle,
                               subtitle: "Watchtower Study",
                               icon: "book.closed.fill",
                               color: .blue) {
                        player.play(urls: [url], title: schedule.watchtowerTitle,
                                    subtitle: schedule.weekLabel, artwork: "book.closed.fill")
                    }
                }
                if !schedule.bibleReadingURLs.isEmpty {
                    ContentRow(title: schedule.bibleReadingTitle,
                               subtitle: "Bible Reading",
                               icon: "text.book.closed.fill",
                               color: .green) {
                        player.play(urls: schedule.bibleReadingURLs,
                                    title: schedule.bibleReadingTitle,
                                    subtitle: schedule.weekLabel, artwork: "text.book.closed.fill")
                    }
                }
                if !schedule.cbsURLs.isEmpty {
                    ContentRow(title: schedule.cbsTitle,
                               subtitle: "Congregation Bible Study",
                               icon: "person.3.fill",
                               color: .purple) {
                        player.play(urls: schedule.cbsURLs,
                                    title: schedule.cbsTitle,
                                    subtitle: schedule.weekLabel, artwork: "person.3.fill")
                    }
                }
                if schedule.mwbURL == nil && schedule.watchtowerURL == nil &&
                   schedule.bibleReadingURLs.isEmpty && schedule.cbsURLs.isEmpty {
                    Label("Content not yet available", systemImage: "clock")
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
