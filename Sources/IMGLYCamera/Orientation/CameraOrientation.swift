import AVFoundation
import UIKit

/// Clockwise UI rotation relative to the portrait camera preview.
enum CameraOrientation: Int, CaseIterable, Sendable {
  case portrait = 0
  case landscapeLeft = 90
  case upsideDown = 180
  case landscapeRight = 270

  /// Gravity is independent of the system's interface rotation lock. Leave a dead band
  /// around diagonals and flat poses so small hand movements do not flip the controls.
  init?(gravityX x: Double, gravityY y: Double, gravityZ z: Double) {
    guard x.isFinite, y.isFinite, z.isFinite, abs(z) < 0.85 else { return nil }
    if abs(x) > abs(y) + 0.15, abs(x) > 0.55 {
      self = x < 0 ? .landscapeLeft : .landscapeRight
    } else if abs(y) > abs(x) + 0.15, abs(y) > 0.55 {
      self = y < 0 ? .portrait : .upsideDown
    } else {
      return nil
    }
  }

  var deviceOrientation: UIDeviceOrientation {
    switch self {
    case .portrait: .portrait
    case .landscapeLeft: .landscapeLeft
    case .upsideDown: .portraitUpsideDown
    case .landscapeRight: .landscapeRight
    }
  }

  init?(_ orientation: UIDeviceOrientation) {
    switch orientation {
    case .portrait: self = .portrait
    case .landscapeLeft: self = .landscapeLeft
    case .portraitUpsideDown: self = .upsideDown
    case .landscapeRight: self = .landscapeRight
    default: return nil
    }
  }

  init?(_ orientation: UIInterfaceOrientation) {
    switch orientation {
    case .portrait: self = .portrait
    case .landscapeRight: self = .landscapeLeft
    case .portraitUpsideDown: self = .upsideDown
    case .landscapeLeft: self = .landscapeRight
    default: return nil
    }
  }

  var isLandscape: Bool {
    self == .landscapeLeft || self == .landscapeRight
  }

  var videoOrientation: AVCaptureVideoOrientation {
    switch self {
    case .portrait: .portrait
    case .landscapeLeft: .landscapeRight
    case .upsideDown: .portraitUpsideDown
    case .landscapeRight: .landscapeLeft
    }
  }

  func rotation(from angle: Double) -> Double {
    let delta = (Double(rawValue) - angle).truncatingRemainder(dividingBy: 360)
    return angle + (delta > 180 ? delta - 360 : delta < -180 ? delta + 360 : delta)
  }

  /// Converts portrait preview geometry into the upright captured file's coordinate system.
  func captureTransform(size: CGSize) -> CGAffineTransform {
    switch self {
    case .portrait: .identity
    case .landscapeLeft: CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: size.width)
    case .upsideDown: CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: size.width, ty: size.height)
    case .landscapeRight: CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: size.height, ty: 0)
    }
  }

  func captureRect(_ rect: CGRect) -> CGRect {
    rect.applying(captureTransform(size: CameraConfiguration.defaultVideoSize))
  }
}

struct CaptureOrientationState {
  private(set) var preview = CameraOrientation.portrait
  private var locked: CameraOrientation?

  var orientation: CameraOrientation {
    locked ?? preview
  }

  mutating func update(_ orientation: CameraOrientation) {
    preview = orientation
  }

  mutating func lock() {
    if locked == nil {
      locked = preview
    }
  }

  mutating func unlock() {
    locked = nil
  }
}
