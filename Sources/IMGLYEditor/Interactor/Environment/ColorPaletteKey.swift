import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct ColorPaletteKey: EnvironmentKey {
  static let defaultValue: [NamedColor] = [
    .init("Blue", .blue),
    .init("Green", .green),
    .init("Yellow", .yellow),
    .init("Red", .red),
    .init("Black", .black),
    .init("White", .white),
    .init("Gray", .gray)
  ]
}

extension EnvironmentValues {
  var imglyColorPalette: [NamedColor] {
    get { self[ColorPaletteKey.self] }
    set { self[ColorPaletteKey.self] = newValue }
  }
}
