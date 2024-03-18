import CoreMedia
@_spi(Internal) import IMGLYCore
import SwiftUI

/// Manage playback state of the IMGLY Engine.
@MainActor
final class Player: ObservableObject {
  @Published var isPlaying = false
  @Published var playheadPosition = CMTime(seconds: 0) {
    didSet {
      guard oldValue != playheadPosition else { return }
      formattedPlayheadPosition = playheadPosition.imgly.formattedDurationStringForPlayer()
    }
  }

  @Published private(set) var formattedPlayheadPosition = CMTime(seconds: 0).imgly.formattedDurationStringForPlayer()
}
