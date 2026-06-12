@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

@_spi(Internal) public struct FillColorIcon: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @_spi(Internal) public init() {}

  @_spi(Internal) public var body: some View {
    if interactor.isColorFill(id) {
      let isEnabled: Binding<Bool> = interactor.bind(id, property: .key(.fillEnabled), default: false)
      // Stack a text block's mixed run colours as stripes; gradient fills keep their blend.
      let multiColorStyle: FillColorImage.MultiColorStyle = interactor.isGradientFill(id) ? .gradient : .stripes

      FillColorImage(
        isEnabled: isEnabled.wrappedValue,
        colors: interactor.bind(
          id,
          property: .key(.fillSolidColor),
          default: [.imgly.black],
          getter: backgroundColorGetter,
        ),
        multiColorStyle: multiColorStyle,
      )
    }
  }

  let backgroundColorGetter: Interactor.PropertyGetter<[CGColor]> = { engine, id, _, _ in
    let fillType: ColorFillType = try engine.block.get(id, .fill, property: .key(.type))
    if fillType == .solid {
      let blockType = try engine.block.getType(id)
      // A text block's run colours, so the swatch can stack mixed colours; else the solid fill.
      if blockType == Interactor.BlockType.text.rawValue {
        let textColors = try engine.block.getTextColors(id).compactMap(\.cgColor)
        if !textColors.isEmpty {
          return textColors
        }
      }
      let color: CGColor = try engine.block.get(id, property: .key(.fillSolidColor))
      return [color]
    } else if fillType == .gradient {
      let colorStops: [Interactor.GradientColorStop] = try engine.block
        .get(id, .fill, property: .key(.fillGradientColors))
      let colors = colorStops.compactMap(\.color.cgColor)
      return colors
    }
    return [.imgly.black]
  }
}

struct StrokeColorIcon: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    if interactor.supportsStroke(id) {
      let isEnabled: Binding<Bool> = interactor.bind(id, property: .key(.strokeEnabled), default: false)
      let color: Binding<CGColor> = interactor.bind(id, property: .key(.strokeColor), default: .imgly.black)

      StrokeColorImage(isEnabled: isEnabled.wrappedValue, color: color)
    }
  }
}
