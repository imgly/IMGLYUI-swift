import SwiftUI
@_spi(Internal) import IMGLYCore

extension PresentationDetent: IMGLYCompatible {}

public extension IMGLY where Wrapped == PresentationDetent {
  /// A tiny presentation detent.
  static let tiny = Wrapped.custom(AdaptiveTinyPresentationDetent.self)
  /// A small presentation detent.
  static let small = Wrapped.custom(AdaptiveSmallPresentationDetent.self)
  /// A medium presentation detent.
  static let medium = Wrapped.custom(AdaptiveMediumPresentationDetent.self)
  /// A large presentation detent.
  static let large = Wrapped.custom(AdaptiveLargePresentationDetent.self)

  internal var identifier: UISheetPresentationController.Detent.Identifier? {
    switch wrapped {
    case .imgly.tiny: AdaptiveTinyPresentationDetent.identifier
    case .imgly.small: AdaptiveSmallPresentationDetent.identifier
    case .imgly.medium: AdaptiveMediumPresentationDetent.identifier
    case .imgly.large: AdaptiveLargePresentationDetent.identifier
    // Identical to UISheetPresentationController.Detent.medium().identifier but without @MainActor constraint.
    case .medium: UISheetPresentationController.Detent.Identifier("com.apple.UIKit.medium")
    // Identical to UISheetPresentationController.Detent.large().identifier but without @MainActor constraint.
    case .large: UISheetPresentationController.Detent.Identifier("com.apple.UIKit.large")
    default:
      nil
    }
  }
}

extension CustomPresentationDetent {
  static var identifier: UISheetPresentationController.Detent.Identifier {
    let typeName = String(describing: Self.self)
    return .init("Custom:" + typeName)
  }
}

private struct AdaptiveTinyPresentationDetent: CustomPresentationDetent {
  static func height(in _: Context) -> CGFloat? {
    160
  }
}

private struct AdaptiveSmallPresentationDetent: CustomPresentationDetent {
  static func height(in context: Context) -> CGFloat? {
    if context.verticalSizeClass == .compact {
      160
    } else {
      280
    }
  }
}

private struct AdaptiveMediumPresentationDetent: CustomPresentationDetent {
  static func height(in context: Context) -> CGFloat? {
    if context.verticalSizeClass == .compact {
      160
    } else {
      340
    }
  }
}

private struct AdaptiveLargePresentationDetent: CustomPresentationDetent {
  static func height(in context: Context) -> CGFloat? {
    // Underlying content should not slide to the background.
    if #available(iOS 17.0, *) {
      context.maxDetentValue * 0.99960
    } else {
      context.maxDetentValue * 0.99977
    }
  }
}
