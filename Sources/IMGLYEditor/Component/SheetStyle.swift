import SwiftUI

/// A style that represents the presentation behavior of a sheet.
public struct SheetStyle: Hashable {
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
  /// - Parameters:
  ///   - isFloating: Whether the sheet should be floating. If `true` the sheet will cover the editor's canvas and its
  /// content, if `false` the canvas will be zoomed to adjust for the size of the sheet so that the canvas' content
  /// won't be covered by the sheet.
  ///   - detent: The initial detent of the sheet. Ensure that the value matches one of the detents that you provide for
  /// the `detents` parameter.
  ///   - detents: A set of supported detents for the sheet. If you provide more that one detent, people can drag the
  /// sheet to resize it.
  ///   - largestUndimmedDetent: The largest detent that doesn't dim the underlying content. If `nil` the underlying
  /// content is always dimmed.
  @available(iOS 16.4, *)
  public init(
    isFloating: Bool,
    detent: PresentationDetent,
    detents: Set<PresentationDetent>,
    largestUndimmedDetent: PresentationDetent?
  ) {
    self.init(isFloating, detent, detents, largestUndimmedDetent: largestUndimmedDetent)
  }

  /// Creates a sheet style with arbitrary detents where the underlying content is always dimmed.
  /// - Parameters:
  ///   - isFloating: Whether the sheet should be floating. If `true` the sheet will cover the editor's canvas and its
  /// content, if `false` the canvas will be zoomed to adjust for the size of the sheet so that the canvas' content
  /// won't be covered by the sheet.
  ///   - detent: The initial detent of the sheet. Ensure that the value matches one of the detents that you provide for
  /// the `detents` parameter.
  ///   - detents: A set of supported detents for the sheet. If you provide more that one detent, people can drag the
  /// sheet to resize it.
  public init(
    isFloating: Bool,
    detent: PresentationDetent,
    detents: Set<PresentationDetent>
  ) {
    self.init(isFloating, detent, detents, largestUndimmedDetent: nil)
  }

  /// Creates a sheet style where the underlying content can be undimmed when exclusively predefined detents are used.
  /// Use ``init(isFloating:detent:detents:largestUndimmedDetent:)`` instead if arbitrary detents are required.
  /// - Parameters:
  ///   - isFloating: Whether the sheet should be floating. If `true` the sheet will cover the editor's canvas and its
  /// content, if `false` the canvas will be zoomed to adjust for the size of the sheet so that the canvas' content
  /// won't be covered by the sheet.
  ///   - detent: The initial detent of the sheet. Ensure that the value matches one of the detents that you provide for
  /// the `detents` parameter.
  ///   - detents: A set of supported detents for the sheet. If you provide more that one detent, people can drag the
  /// sheet to resize it.
  ///   - largestUndimmedDetent: The largest detent that doesn't dim the underlying content. If `nil` the underlying
  /// content is always dimmed. If it is not `nil` `PresentationDetent.medium`, `.large`, ``IMGLY/tiny``,
  /// ``IMGLY/small``, ``IMGLY/medium``, or ``IMGLY/large`` must be used. An assert is triggered on violations. By
  /// default, `nil` is used.
  /// - Returns: The created sheet style.
  public static
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
        "If `largestUndimmedDetent` is not `nil` `PresentationDetent.medium`, `.large`, `.imgly.tiny`, `.imgly.small`, `.imgly.medium`, or `.imgly.large` must be used."
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

public extension SheetStyle {
  /// Creates a default sheet style ``withPredefinedDetents(isFloating:detent:detents:largestUndimmedDetent:)``.
  /// - Parameters:
  ///   - isFloating: Whether the sheet should be floating. If `true` the sheet will cover the editor's canvas and its
  /// content, if `false` the canvas will be zoomed to adjust for the size of the sheet so that the canvas' content
  /// won't be covered by the sheet. By default, `false` is used.
  ///   - detent: The initial detent of the sheet. Ensure that the value matches one of the detents that you provide for
  /// the `detents` parameter. By default, the ``IMGLY/medium`` detent is used.
  ///   - detents: A set of supported detents for the sheet. If you provide more that one detent, people can drag the
  /// sheet to resize it. By default, the ``IMGLY/medium`` and ``IMGLY/large`` detents are used.
  /// - Returns: The created sheet style.
  static func `default`(isFloating: Bool = false,
                        detent: PresentationDetent = .imgly.medium,
                        detents: Set<PresentationDetent> = [.imgly.medium, .imgly.large]) -> Self {
    .withPredefinedDetents(isFloating: isFloating, detent: detent, detents: detents,
                           largestUndimmedDetent: detents.largestUndimmedDetent)
  }

  /// Creates a floating sheet style  ``withPredefinedDetents(isFloating:detent:detents:largestUndimmedDetent:)`` that
  /// is used for adding assets.
  /// - Parameters:
  ///   - detent: The initial detent of the sheet. Ensure that the value matches one of the detents that you provide for
  /// the `detents` parameter. By default, the ``IMGLY/large`` detent is used.
  ///   - detents: A set of supported detents for the sheet. If you provide more that one detent, people can drag the
  /// sheet to resize it. By default, the ``IMGLY/medium`` and ``IMGLY/large`` detents are used.
  /// - Returns: The created sheet style.
  static func addAsset(detent: PresentationDetent = .imgly.large,
                       detents: Set<PresentationDetent> = [.imgly.medium, .imgly.large]) -> Self {
    .default(isFloating: true, detent: detent, detents: detents)
  }

  /// Creates a non-floating sheet style  ``withPredefinedDetents(isFloating:detent:detents:largestUndimmedDetent:)``
  /// that does not allow to resize the sheet.
  /// - Parameter detent: The detent of the sheet.
  /// - Returns: The created sheet style.
  static func only(detent: PresentationDetent) -> Self {
    .default(isFloating: false, detent: detent, detents: [detent])
  }
}
