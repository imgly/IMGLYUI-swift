import Foundation

class Wave: ObservableObject, Identifiable {
  @Published var value: Float
  @Published var recorded: Bool

  var position: Int

  init(value: Float, recorded: Bool, position: Int) {
    self.value = value
    self.recorded = recorded
    self.position = position
  }
}

// Extension to Dictionary where the elements are of type Wave
extension [Int: Wave] {
  mutating func resetRecordedFlags() {
    for (_, wave) in self where wave.recorded {
      wave.recorded = false
    }
  }

  func containsAudioWave(withPosition position: Int) -> Bool {
    self[position] != nil
  }
}
