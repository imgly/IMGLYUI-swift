import SwiftUI
@_spi(Internal) import IMGLYCoreUI

enum ColorPalette {
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
