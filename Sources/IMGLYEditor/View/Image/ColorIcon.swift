@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct FillColorIcon: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    if interactor.hasColorFill(id) {
      let isEnabled: Binding<Bool> = interactor.bind(id, property: .key(.fillEnabled), default: false)

      FillColorImage(
        isEnabled: isEnabled.wrappedValue,
        colors: interactor.bind(
          id,
          property: .key(.fillSolidColor),
          default: [.imgly.black],
          getter: backgroundColorGetter
        )
      )
    }
  }

  let backgroundColorGetter: Interactor.PropertyGetter<[CGColor]> = { engine, id, _, _ in
    let fillType: ColorFillType = try engine.block.get(id, .fill, property: .key(.type))
    if fillType == .solid {
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
    if interactor.hasStroke(id) {
      let isEnabled: Binding<Bool> = interactor.bind(id, property: .key(.strokeEnabled), default: false)
      let color: Binding<CGColor> = interactor.bind(id, property: .key(.strokeColor), default: .imgly.black)

      StrokeColorImage(isEnabled: isEnabled.wrappedValue, color: color)
    }
  }
}
