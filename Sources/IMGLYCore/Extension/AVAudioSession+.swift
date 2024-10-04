import AVFoundation
import Foundation
import UIKit

private enum AudioSessionStateError: Swift.Error {
  case stateQueueEmpty, test
}

@_spi(Internal) public extension AVAudioSession {
  class StateQueue {
    private var states: [SessionState] = []

    func push(state: SessionState) {
      states.append(state)
    }

    func pop() throws -> SessionState {
      if states.isEmpty {
        throw AudioSessionStateError.stateQueueEmpty
      }

      return states.removeFirst()
    }
  }

  struct SessionState {
    let category: AVAudioSession.Category
    let mode: AVAudioSession.Mode
    let categoryOptions: AVAudioSession.CategoryOptions

    init(session: AVAudioSession) {
      category = session.category
      mode = session.mode
      categoryOptions = session.categoryOptions
    }
  }

  private static let queue = StateQueue()

  static func push() {
    let state = SessionState(session: session)
    queue.push(state: state)
  }

  static func prepareForRecording() throws {
    try session.setCategory(
      .playAndRecord,
      options: [.defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
    )
  }

  static func prepareForPlayback() throws {
    try session.setCategory(.playback)
  }

  static func pop() throws {
    let state = try queue.pop()
    try session.setCategory(state.category, mode: state.mode, options: state.categoryOptions)
  }

  private static var session: AVAudioSession {
    sharedInstance()
  }
}
