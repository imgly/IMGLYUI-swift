import SwiftUI

@_spi(Unstable) public struct SheetStyle: Hashable {
  let isFloating: Bool
  var detent: PresentationDetent
  let detents: Set<PresentationDetent>
  let largestUndimmedDetent: PresentationDetent?

  private init(_ isFloating: Bool,
               _ detent: PresentationDetent,
               _ detents: Set<PresentationDetent>,
               largestUndimmedDetent: PresentationDetent?) {
    self.isFloating = isFloating
    self.detent = detent
    self.detents = detents
    self.largestUndimmedDetent = largestUndimmedDetent
  }

  /// Creates a sheet style with arbitrary detents where the underlying content can be undimmed.
  @available(iOS 16.4, *)
  @_spi(Unstable) public init(
    isFloating: Bool,
    detent: PresentationDetent,
    detents: Set<PresentationDetent>,
    largestUndimmedDetent: PresentationDetent?
  ) {
    self.init(isFloating, detent, detents, largestUndimmedDetent: largestUndimmedDetent)
  }

  /// Creates a sheet style with arbitrary detents where the underlying content is always dimmed.
  @_spi(Unstable) public init(
    isFloating: Bool,
    detent: PresentationDetent,
    detents: Set<PresentationDetent>
  ) {
    self.init(isFloating, detent, detents, largestUndimmedDetent: nil)
  }

  /// Creates a sheet style where the underlying content can be undimmed when exclusively predefined detents are used.
  /// - Attention: If `largestUndimmedDetent` is not nil `PresentationDetent.medium`, `.large`, `.imgly.tiny`,
  /// `.imgly.small`, `.imgly.medium`, or `.imgly.large` must be used. An assert is triggered on violations.
  @_spi(Unstable) public static
  func withPredefinedDetents(
    isFloating: Bool,
    detent: PresentationDetent,
    detents: Set<PresentationDetent>,
    largestUndimmedDetent: PresentationDetent? = nil
  ) -> Self {
    if let largestUndimmedDetent {
      let allDetentsArePredefined = withArrayBuilder {
        detent
        detents.map { $0 }
        largestUndimmedDetent
      }.allSatisfy(\.isPredefined)
      assert(
        allDetentsArePredefined,
        // swiftlint:disable:next line_length
        "If `largestUndimmedDetent` is not nil `PresentationDetent.medium`, `.large`, `.imgly.tiny`, `.imgly.small`, `.imgly.medium`, or `.imgly.large` must be used."
      )
    }
    return self.init(isFloating, detent, detents, largestUndimmedDetent: largestUndimmedDetent)
  }
}

private extension PresentationDetent {
  var isPredefined: Bool { imgly.identifier != nil }
}

extension Set<PresentationDetent> {
  var largestUndimmedDetent: PresentationDetent? {
    if contains(.medium) {
      .medium
    } else if contains(.imgly.medium) {
      .imgly.medium
    } else if contains(.imgly.small) {
      .imgly.small
    } else if contains(.imgly.tiny) {
      .imgly.tiny
    } else {
      nil
    }
  }
}

@_spi(Unstable) public extension SheetStyle {
  static func `default`(isFloating: Bool = false,
                        detent: PresentationDetent = .imgly.medium,
                        detents: Set<PresentationDetent> = [.imgly.medium, .imgly.large]) -> Self {
    .withPredefinedDetents(isFloating: isFloating, detent: detent, detents: detents,
                           largestUndimmedDetent: detents.largestUndimmedDetent)
  }

  static func addAsset(detent: PresentationDetent = .imgly.large,
                       detents: Set<PresentationDetent> = [.imgly.medium, .imgly.large]) -> Self {
    .default(isFloating: true, detent: detent, detents: detents)
  }

  static func only(detent: PresentationDetent) -> Self {
    .default(isFloating: false, detent: detent, detents: [detent])
  }
}
