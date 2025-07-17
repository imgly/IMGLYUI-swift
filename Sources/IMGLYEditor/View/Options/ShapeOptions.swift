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
      Section("Corner Radius") {
        PropertySlider<Float>("Corner Radius", in: 0 ... 1, property: .key(.shapePolygonCornerRadius),
                              setter: { engine, blocks, propertyBlock, property, value, completion in
                                let changed = try blocks.filter {
                                  let cornerRadius: Float = try engine.block.get($0, propertyBlock, property: property)
                                  let ratio = try engine.block.getRadiusFactor($0) * value
                                  return cornerRadius != ratio
                                }
                                try changed.forEach {
                                  let ratio = try engine.block.getRadiusFactor($0) * value
                                  try engine.block.set($0, propertyBlock, property: property, value: ratio)
                                }
                                let hasChanges = !changed.isEmpty
                                return try (completion?(engine, blocks, hasChanges) ?? false) || hasChanges
                              }, getter: { engine, block, propertyBlock, property in
                                let cornerRadius: Float = try engine.block.get(block, propertyBlock, property: property)
                                return try cornerRadius / engine.block.getRadiusFactor(block)
                              }, propertyBlock: .shape)
      }
    case .rect:
      Section("Corner Radius") {
        rectCornerRadiusSlider
      }
    default:
      EmptyView()
    }
  }

  @ViewBuilder var rectCornerRadiusSlider: some View {
    RawSlider<Float>("Corner Radius", in: 0 ... 1) { engine, blocks, value, completion in
      let changed = try blocks.filter {
        let ratio = try engine.block.getRadiusFactor($0) * value
        let cornerRadiusTL: Float = try engine.block.get($0, .shape, property: .key(.shapeRectCornerRadiusTL))
        let cornerRadiusTR: Float = try engine.block.get($0, .shape, property: .key(.shapeRectCornerRadiusTR))
        let cornerRadiusBL: Float = try engine.block.get($0, .shape, property: .key(.shapeRectCornerRadiusBL))
        let cornerRadiusBR: Float = try engine.block.get($0, .shape, property: .key(.shapeRectCornerRadiusBR))
        return cornerRadiusTL != ratio || cornerRadiusTR != ratio || cornerRadiusBL != ratio || cornerRadiusBR != ratio
      }

      try changed.forEach {
        let ratio = try engine.block.getRadiusFactor($0) * value
        try engine.block.set($0, .shape, property: .key(.shapeRectCornerRadiusTL), value: ratio)
        try engine.block.set($0, .shape, property: .key(.shapeRectCornerRadiusTR), value: ratio)
        try engine.block.set($0, .shape, property: .key(.shapeRectCornerRadiusBL), value: ratio)
        try engine.block.set($0, .shape, property: .key(.shapeRectCornerRadiusBR), value: ratio)
      }

      let hasChanges = !changed.isEmpty
      return try (completion?(engine, blocks, hasChanges) ?? false) || hasChanges
    } getter: { engine, block in
      let cornerRadiusTL: Float = try engine.block.get(block, .shape, property: .key(.shapeRectCornerRadiusTL))
      let cornerRadiusTR: Float = try engine.block.get(block, .shape, property: .key(.shapeRectCornerRadiusTR))
      let cornerRadiusBL: Float = try engine.block.get(block, .shape, property: .key(.shapeRectCornerRadiusBL))
      let cornerRadiusBR: Float = try engine.block.get(block, .shape, property: .key(.shapeRectCornerRadiusBR))
      let cornerRadius = [
        cornerRadiusTL,
        cornerRadiusTR,
        cornerRadiusBL,
        cornerRadiusBR,
      ].max() ?? 0

      return try cornerRadius / engine.block.getRadiusFactor(block)
    }
  }

  var body: some View {
    List {
      shapeOptions
    }
  }
}

// MARK: - Helpers

import IMGLYEngine

private extension BlockAPI {
  func getRadiusFactor(_ id: DesignBlockID) throws -> Float {
    let height = try getHeight(id)
    let width = try getWidth(id)
    let min = min(width, height)
    return min / 2
  }
}
