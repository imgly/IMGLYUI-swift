enum FlashMode {
  case off
  case on

  mutating func toggle() {
    switch self {
    case .off: self = .on
    case .on: self = .off
    }
  }
}
