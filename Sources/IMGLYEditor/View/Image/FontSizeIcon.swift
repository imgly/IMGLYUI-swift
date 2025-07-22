@_spi(Internal) import IMGLYCore
import SwiftUI

@_spi(Internal) public struct FontSizeIcon: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @_spi(Internal) public init() {}

  @_spi(Internal) public var body: some View {
    let fontSize: Binding<Float?> = interactor.bind(id, property: .key(.textFontSize))

    if let fontSize = fontSize.wrappedValue {
      FontSizeImage(fontSize: fontSize)
    }
  }
}
