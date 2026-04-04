import AVFoundation
import MediaPlayer

@MainActor
final class AudioPlayer: ObservableObject {
    static let shared = AudioPlayer()

    @Published var isPlaying = false
    @Published var currentTitle = ""
    @Published var currentSubtitle = ""
    @Published var currentArtwork = ""  // SF symbol name

    private var player: AVQueuePlayer?
    private var playerItems: [AVPlayerItem] = []
    private var currentIndex = 0
    // Single token — replaced on every play() to prevent observer accumulation
    private var itemEndObserver: NSObjectProtocol?

    private init() {
        // Audio session is set up once here; AppDelegate does NOT duplicate this
        setupAudioSession()
        setupRemoteCommands()
        setupInterruptionHandler()
    }

    // MARK: - Playback control

    func play(urls: [URL], startIndex: Int = 0, title: String, subtitle: String, artwork: String = "music.note") {
        stop()
        guard !urls.isEmpty, startIndex < urls.count else { return }

        currentTitle    = title
        currentSubtitle = subtitle
        currentArtwork  = artwork
        currentIndex    = startIndex

        playerItems = urls.map { AVPlayerItem(url: $0) }
        player = AVQueuePlayer(items: Array(playerItems.dropFirst(startIndex)))
        player?.play()
        isPlaying = true
        updateNowPlaying()
        observeItemEnd()
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlaying()
    }

    func skipForward() {
        guard let player, currentIndex + 1 < playerItems.count else { return }
        currentIndex += 1
        player.advanceToNextItem()
        updateNowPlaying()
    }

    func skipBackward() {
        if let player, let current = player.currentItem {
            let pos = current.currentTime().seconds
            if pos < 3 && currentIndex > 0 {
                requeue(from: currentIndex - 1)
            } else {
                player.seek(to: .zero)
            }
        }
    }

    func stop() {
        removeItemEndObserver()
        player?.pause()
        player = nil
        playerItems = []
        isPlaying = false
    }

    // MARK: - Private

    private func requeue(from index: Int) {
        guard index >= 0, index < playerItems.count else { return }
        currentIndex = index
        let remaining = Array(playerItems.dropFirst(index))
        player = AVQueuePlayer(items: remaining)
        player?.play()
        observeItemEnd()
        updateNowPlaying()
    }

    private func setupInterruptionHandler() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            guard let userInfo = note.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                if type == .began {
                    self.player?.pause()
                    self.isPlaying = false
                    self.updateNowPlaying()
                } else if type == .ended {
                    if let optValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                       AVAudioSession.InterruptionOptions(rawValue: optValue).contains(.shouldResume) {
                        try? AVAudioSession.sharedInstance().setActive(true)
                        self.player?.play()
                        self.isPlaying = true
                        self.updateNowPlaying()
                    }
                }
            }
        }
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }

    private func observeItemEnd() {
        removeItemEndObserver()
        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.playerItemDidEnd() }
        }
    }

    private func removeItemEndObserver() {
        if let token = itemEndObserver {
            NotificationCenter.default.removeObserver(token)
            itemEndObserver = nil
        }
    }

    private func playerItemDidEnd() {
        currentIndex += 1
        if currentIndex >= playerItems.count {
            isPlaying = false
        }
        updateNowPlaying()
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget          { [weak self] _ in Task { @MainActor [weak self] in self?.togglePlayPause() }; return .success }
        center.pauseCommand.addTarget         { [weak self] _ in Task { @MainActor [weak self] in self?.togglePlayPause() }; return .success }
        center.nextTrackCommand.addTarget     { [weak self] _ in Task { @MainActor [weak self] in self?.skipForward() };     return .success }
        center.previousTrackCommand.addTarget { [weak self] _ in Task { @MainActor [weak self] in self?.skipBackward() };    return .success }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in Task { @MainActor [weak self] in self?.togglePlayPause() }; return .success }
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:            currentTitle,
            MPMediaItemPropertyArtist:           currentSubtitle,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPMediaItemPropertyMediaType:        MPMediaType.podcast.rawValue,
        ]
        if let player, let item = player.currentItem {
            let duration = item.asset.duration.seconds
            let position = item.currentTime().seconds
            if duration.isFinite { info[MPMediaItemPropertyPlaybackDuration] = duration }
            if position.isFinite { info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
