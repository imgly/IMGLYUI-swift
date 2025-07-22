import SwiftUI

enum CountdownMode: TimeInterval, CaseIterable {
  case count3 = 3
  case count10 = 10
  case disabled = 0
}

extension CountdownMode {
  var name: LocalizedStringResource {
    switch self {
    case .count3:
      .imgly.localized("ly_img_camera_timer_option_3")
    case .count10:
      .imgly.localized("ly_img_camera_timer_option_10")
    case .disabled:
      .imgly.localized("ly_img_camera_timer_option_off")
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
