import SwiftUI

extension CameraOrientation {
  var closeAlignment: Alignment {
    switch self {
    case .portrait: .topLeading
    case .landscapeLeft: .topTrailing
    case .upsideDown: .bottomTrailing
    case .landscapeRight: .bottomLeading
    }
  }

  var timecodeAlignment: Alignment {
    switch self {
    case .portrait, .upsideDown: .top
    case .landscapeLeft: .trailing
    case .landscapeRight: .leading
    }
  }

  var featuresAlignment: Alignment {
    switch self {
    case .portrait: .leading
    case .landscapeLeft, .landscapeRight: .top
    case .upsideDown: .trailing
    }
  }

  var limitAlignment: Alignment {
    switch self {
    case .portrait: .bottom
    case .landscapeLeft: .leading
    case .upsideDown: .top
    case .landscapeRight: .trailing
    }
  }
}
