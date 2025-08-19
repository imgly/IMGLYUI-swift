import AVFoundation
import Combine
import CoreMedia
import SwiftUI
@_spi(Internal) import IMGLYCore

class AudioPreviewPlayer: ObservableObject, @unchecked Sendable {
  private var player: AVPlayer?
  private var cancellables: Set<AnyCancellable> = []
  private var timeObserver: Any?

  @Published private(set) var formattedPlayheadPosition = CMTime(seconds: 0).imgly.formattedDurationStringForPlayer()
  @Published private(set) var state: PreviewPlayerState = .stopped
  @Published private(set) var playheadPosition = CMTime(seconds: 0) {
    didSet {
      guard oldValue != playheadPosition else { return }
      formattedPlayheadPosition = playheadPosition.imgly.formattedDurationStringForPlayer()
    }
  }

  @Published var currentAsset: URL? {
    didSet {
      if let currentAsset {
        setAudioSource(url: currentAsset)
      }
    }
  }

  static let shared = AudioPreviewPlayer()

  private init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(stop),
      name: .AVPlayerItemDidPlayToEndTime,
      object: nil,
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    cancellables.forEach { $0.cancel() }
  }

  private func setAudioSource(url: URL) {
    let playerItem = AVPlayerItem(url: url)
    state = .loading
    player = AVPlayer(playerItem: playerItem)
    timeObserver = player?.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.1, preferredTimescale: 10),
      queue: DispatchQueue.main,
    ) { [weak self] time in
      self?.playheadPosition = time
    }

    playerItem.publisher(for: \.status)
      .sink { [weak self] status in
        guard let self else { return }
        switch status {
        case .readyToPlay:
          player?.play()
          state = .playing
        case .failed:
          state = .stopped
        default:
          break
        }
      }
      .store(in: &cancellables)
  }

  @objc func stop() {
    if let timeObserver {
      player?.removeTimeObserver(timeObserver)
      self.timeObserver = nil
    }
    playheadPosition = CMTime(seconds: 0)
    state = .stopped
    player?.pause()
  }
}
