@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct ShapeOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @ViewBuilder var shapeOptions: some View {
    switch interactor.shapeType(id) {
    case .line:
      Section("Line Width") {
        let setter: Interactor.PropertySetter<Float> = { engine, blocks, _, _, value, completion in
          let changed = try blocks.filter {
            try engine.block.getHeight($0) != value
          }

          try changed.forEach {
            try engine.block.setWidth($0, value: engine.block.getFrameWidth($0))
            try engine.block.setHeight($0, value: value)
          }

          let didChange = !changed.isEmpty
          return try (completion?(engine, blocks, didChange) ?? false) || didChange
        }
        PropertySlider<Float>("Line Width", in: 0.1 ... 30, property: .key(.lastFrameHeight), setter: setter)
      }
    case .star:
      Section("Points") {
        PropertySlider<Float>("Points", in: 3 ... 12, property: .key(.shapeStarPoints), propertyBlock: .shape)
      }
      Section("Inner Diameter") {
        PropertySlider<Float>("Inner Diameter", in: 0.1 ... 1, property: .key(.shapeStarInnerDiameter),
                              propertyBlock: .shape)
      }
    case .polygon:
      Section("Sides") {
        PropertySlider<Float>("Sides", in: 3 ... 12, property: .key(.shapePolygonSides), propertyBlock: .shape)
      }
    default:
      EmptyView()
    }
  }

  var body: some View {
    List {
      if interactor.sheetType(id) == .shape {
        shapeOptions
      }
    }
  }
}
