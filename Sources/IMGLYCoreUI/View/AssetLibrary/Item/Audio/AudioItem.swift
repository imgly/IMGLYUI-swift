import Combine
import CoreMedia
@_spi(Internal) import IMGLYCore
import SwiftUI

struct AudioItem: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  @EnvironmentObject private var audioPreviewPlayer: AudioPreviewPlayer

  @State private var playerState: PreviewPlayerState?
  @State private var currentTime: CMTime?
  @State private var formattedTime: String?

  private var isPlaying: Bool {
    playerState == .playing
  }

  private var isLoading: Bool {
    playerState == .loading
  }

  let asset: AssetItem

  var body: some View {
    item
      .onChange(of: audioPreviewPlayer.currentAsset) { newValue in
        guard case let .asset(asset) = asset, let url = asset.previewURLorURL else {
          return
        }
        if newValue != url {
          withAnimation(.easeInOut) {
            playerState = .stopped
          }
          currentTime = .init(seconds: 0)
          formattedTime = nil
        }
      }
      .onReceive(Publishers.Zip4(
        audioPreviewPlayer.$currentAsset,
        audioPreviewPlayer.$state,
        audioPreviewPlayer.$playheadPosition,
        audioPreviewPlayer.$formattedPlayheadPosition
      )
      .filter { currentAsset, _, _, _ in
        guard case let .asset(asset) = asset else {
          return false
        }
        return currentAsset == asset.previewURLorURL
      }.map { _, state, currentTime, formattedTime in
        (state, currentTime, formattedTime)
      }) { state, currentTime, formattedTime in
        if playerState != state {
          withAnimation(.easeInOut) {
            playerState = state
          }
        }
        self.currentTime = currentTime
        self.formattedTime = formattedTime
      }
  }

  @ViewBuilder private var item: some View {
    HStack(spacing: 0) {
      thumbnail
        .padding(.trailing, 16)
      switch asset {
      case let .asset(asset):
        titleAndArtist(asset: asset)
        Spacer(minLength: 16)
        if let duration = duration(asset: asset) {
          HStack(spacing: 0) {
            if isPlaying {
              Text((formattedTime ?? "") + " / ")
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(.primary)
            }
            Text(duration)
              .font(.caption.weight(.medium).monospacedDigit())
              .foregroundStyle(.secondary)
          }
        }
      case .placeholder:
        GridItemBackground()
          .frame(width: 120, height: 24)
        Spacer()
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      guard case let .asset(asset) = asset else {
        return
      }
      interactor.assetTapped(sourceID: asset.sourceID, asset: asset.result)
    }
    .frame(height: 56)
    .padding([.top, .bottom], 8)
  }

  @ViewBuilder private var thumbnail: some View {
    ZStack {
      let roundedCorners = isPlaying || isLoading
      ImageItem(asset: asset)
        .cornerRadius(roundedCorners ? 28 : 8)
        .shadow(color: .black.opacity(roundedCorners ? 0.25 : 0), radius: 6, x: 0, y: 2)
        .shadow(color: .black.opacity(roundedCorners ? 0.05 : 0), radius: 4, x: 1, y: 1)
      if case let .asset(asset) = asset {
        Button {
          playPause()
        } label: {
          ZStack {
            Circle()
              .fill(.black)
              .frame(width: 40, height: 40)
              .opacity(0.4)
            if isLoading {
              ProgressView()
                .tint(.white)
            } else {
              Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .foregroundColor(.white)
                .contentShape(Rectangle())
            }
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
        if isPlaying {
          if let duration = asset.result.duration, let time = currentTime?.seconds {
            let progress = time / duration
            AudioProgressIndicator(progress: progress)
          }
        }
      }
    }
  }

  @ViewBuilder private func titleAndArtist(asset: AssetLoader.Asset) -> some View {
    let title = asset.result.title ?? asset.result.label
    let tags = asset.result.tags?.joined(separator: " · ") as String?
    let artist = asset.result.artist

    VStack(alignment: .leading, spacing: 2) {
      Text(title ?? "")
        .font(.body)
        .lineLimit(1)
      if let artist, !artist.isEmpty {
        Text(artist)
          .font(.caption)
          .lineLimit(1)
      }
      if let tags, !tags.isEmpty {
        Text(tags)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }
    }
  }

  private func duration(asset: AssetLoader.Asset) -> String? {
    guard let duration = asset.result.duration else {
      return nil
    }
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .positional
    return formatter.string(from: duration)
  }

  private func playPause() {
    guard case let .asset(asset) = asset, let url = asset.previewURLorURL else { return }
    if audioPreviewPlayer.state == .playing {
      audioPreviewPlayer.stop()
      if audioPreviewPlayer.currentAsset != url {
        audioPreviewPlayer.currentAsset = url
      }
    } else {
      audioPreviewPlayer.currentAsset = url
    }
  }
}

struct AudioItem_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
