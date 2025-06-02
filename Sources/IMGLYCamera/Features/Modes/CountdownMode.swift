import SwiftUI

enum CountdownMode: TimeInterval, CaseIterable {
  case count3 = 3
  case count10 = 10
  case disabled = 0
}

extension CountdownMode {
  var name: LocalizedStringKey {
    switch self {
    case .count3:
      "3 Seconds"
    case .count10:
      "10 Seconds"
    case .disabled:
      "Off"
    }
  }

  var image: Image {
    switch self {
    case .count3: Image("custom.timer.3", bundle: .module)
    case .count10: Image("custom.timer.10", bundle: .module)
    case .disabled: Image(systemName: "timer")
    }
  }
}
