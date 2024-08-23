import SwiftUI

extension PresentationDetent {
  static let adaptiveTiny = Self.custom(AdaptiveTinyPresentationDetent.self)
  static let adaptiveSmall = Self.custom(AdaptiveSmallPresentationDetent.self)
  static let adaptiveMedium = Self.custom(AdaptiveMediumPresentationDetent.self)
  static let adaptiveLarge = Self.custom(AdaptiveLargePresentationDetent.self)

  @MainActor
  var identifier: UISheetPresentationController.Detent.Identifier? {
    switch self {
    case .adaptiveTiny: AdaptiveTinyPresentationDetent.identifier
    case .adaptiveSmall: AdaptiveSmallPresentationDetent.identifier
    case .adaptiveMedium: AdaptiveMediumPresentationDetent.identifier
    case .adaptiveLarge: AdaptiveLargePresentationDetent.identifier
    case .medium: UISheetPresentationController.Detent.medium().identifier
    case .large: UISheetPresentationController.Detent.large().identifier
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
    context.maxDetentValue * 0.99977
  }
}
