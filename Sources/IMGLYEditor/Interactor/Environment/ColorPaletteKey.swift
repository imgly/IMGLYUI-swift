import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct ColorPaletteKey: EnvironmentKey {
  static let defaultValue: [NamedColor] = [
    .init("Blue", .imgly.blue),
    .init("Green", .imgly.green),
    .init("Yellow", .imgly.yellow),
    .init("Red", .imgly.red),
    .init("Black", .imgly.black),
    .init("White", .imgly.white),
    .init("Gray", .imgly.gray),
  ]
}

extension EnvironmentValues {
  var imglyColorPalette: [NamedColor] {
    get { self[ColorPaletteKey.self] }
    set { self[ColorPaletteKey.self] = newValue }
  }
}
