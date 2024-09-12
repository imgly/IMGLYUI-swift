import SwiftUI

enum CountdownMode: TimeInterval, CaseIterable {
  case count10 = 10
  case count3 = 3
  case disabled = 0
}

extension CountdownMode {
  var name: LocalizedStringKey {
    switch self {
    case .count10:
      "10 Seconds"
    case .count3:
      "3 Seconds"
    case .disabled:
      "Off"
    }
  }
}
