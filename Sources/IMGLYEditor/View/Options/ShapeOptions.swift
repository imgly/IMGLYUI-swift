@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct ShapeOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @ViewBuilder var shapeOptions: some View {
    switch interactor.shapeType(id) {
    case .star:
      Section {
        PropertyStepper<Float>(
          .imgly.localized("ly_img_editor_sheet_shape_label_points"),
          in: 3 ... 12,
          step: 1,
          property: .key(.shapeStarPoints),
          decimals: 0,
          propertyBlock: .shape,
        )
      }
      Section {
        // The percentage heuristic would otherwise show a fabricated 0-100%
        // and render this range's non-zero minimum (0.1) as 0.
        PropertySlider<Float>(
          .imgly.localized("ly_img_editor_sheet_shape_label_inner_diameter"),
          in: 0.1 ... 1,
          property: .key(.shapeStarInnerDiameter),
          propertyBlock: .shape,
          disableAutoPercentage: true,
        )
      } header: {
        Text(.imgly.localized("ly_img_editor_sheet_shape_label_inner_diameter"))
      }
    case .polygon:
      Section {
        PropertyStepper<Float>(
          .imgly.localized("ly_img_editor_sheet_shape_label_sides"),
          in: 3 ... 12,
          step: 1,
          property: .key(.shapePolygonSides),
          decimals: 0,
          propertyBlock: .shape,
        )
      }
      Section {
        PropertySlider<Float>(
          .imgly.localized("ly_img_editor_sheet_shape_label_round_corners"),
          in: 0 ... 1,
          property: .key(.shapePolygonCornerRadius),
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
          },
          getter: { engine, block, propertyBlock, property in
            let cornerRadius: Float = try engine.block.get(block, propertyBlock, property: property)
            return try cornerRadius / engine.block.getRadiusFactor(block)
          },
          propertyBlock: .shape,
          showsReadout: false,
        )
      } header: {
        Text(.imgly.localized("ly_img_editor_sheet_shape_label_round_corners"))
      }
    case .rect:
      Section {
        rectCornerRadiusSlider
      } header: {
        Text(.imgly.localized("ly_img_editor_sheet_shape_label_round_corners"))
      }
    default:
      EmptyView()
    }
  }

  var rectCornerRadiusSlider: some View {
    PropertySlider<Float>(
      .imgly.localized("ly_img_editor_sheet_shape_label_round_corners"),
      in: 0 ... 1,
      property: .raw("shape/rect/cornerRadius"),
      setter: { engine, blocks, _, _, value, completion in
        let changed = try blocks.filter {
          let ratio = try engine.block.getRadiusFactor($0) * value
          let cornerRadiusTL: Float = try engine.block.get($0, .shape, property: .key(.shapeRectCornerRadiusTL))
          let cornerRadiusTR: Float = try engine.block.get($0, .shape, property: .key(.shapeRectCornerRadiusTR))
          let cornerRadiusBL: Float = try engine.block.get($0, .shape, property: .key(.shapeRectCornerRadiusBL))
          let cornerRadiusBR: Float = try engine.block.get($0, .shape, property: .key(.shapeRectCornerRadiusBR))
          return cornerRadiusTL != ratio || cornerRadiusTR != ratio || cornerRadiusBL != ratio || cornerRadiusBR !=
            ratio
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
      },
      getter: { engine, block, _, _ in
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
      },
      propertyBlock: .shape,
      showsReadout: false,
    )
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
