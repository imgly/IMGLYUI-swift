import CoreMedia
import Foundation
@_spi(Internal) import IMGLYCore

struct VideoDurationConstraints: Equatable {
  var minimumDuration: TimeInterval?
  var maximumDuration: TimeInterval?

  init(minimumDuration: TimeInterval? = nil, maximumDuration: TimeInterval? = nil) {
    self.minimumDuration = minimumDuration
    self.maximumDuration = maximumDuration
  }

  var minimumTime: CMTime? {
    minimumDuration.map { CMTime(seconds: $0) }
  }

  var maximumTime: CMTime? {
    maximumDuration.map { CMTime(seconds: $0) }
  }

  func normalized() -> VideoDurationConstraints {
    let minValue = normalizeValue(minimumDuration)
    let maxValue = normalizeValue(maximumDuration)
    let normalizedMax: TimeInterval? = if let minValue, let maxValue, maxValue < minValue {
      nil
    } else {
      maxValue
    }
    return VideoDurationConstraints(minimumDuration: minValue, maximumDuration: normalizedMax)
  }

  private func normalizeValue(_ value: TimeInterval?) -> TimeInterval? {
    guard let value, value.isFinite, value > 0 else {
      return nil
    }
    return value
  }
}

@MainActor
protocol VideoDurationConstraintsProviding {
  var videoDurationConstraints: VideoDurationConstraints { get }
}
