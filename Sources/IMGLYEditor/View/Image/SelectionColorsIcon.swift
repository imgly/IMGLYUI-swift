import SwiftUI
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public struct SelectionColorsIcon: View {
  @EnvironmentObject private var interactor: Interactor

  @_spi(Internal) public init() {}

  @_spi(Internal) public var body: some View {
    HStack(spacing: -16) {
      let sections = interactor.bind(interactor.selectionColors, completion: nil)
      ForEach(sections, id: \.name) { section in
        ForEach(section.colors) { color in
          FillColorImage(isEnabled: true, color: color.binding)
        }
      }
    }
  }
}
