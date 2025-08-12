@_spi(Internal) import IMGLYCore
@_spi(Internal) import enum IMGLYCoreUI.StrokeStyle
import SwiftUI

struct BackgroundOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @Binding var isEnabled: Bool

  // MARK: - Constants

  private enum Defaults {
    static let fallbackSize: Float = 100
    static let fallbackRadius: Float = 50
    static let maxScaleFactor: Float = 0.5
  }

  // MARK: - Computed Properties

  private var maxVerticalPadding: Float {
    guard let id, let engine = interactor.engine else { return Defaults.fallbackSize }

    let currentTop: Float = (try? engine.block.get(id, property: .key(.backgroundColorPaddingTop))) ?? 0
    let currentBottom: Float = (try? engine.block.get(id, property: .key(.backgroundColorPaddingBottom))) ?? 0
    let height: Float = (try? Float(engine.block.getFrameHeight(id))) ?? Defaults.fallbackSize

    return max(height, currentTop, currentBottom)
  }

  private var maxHorizontalPadding: Float {
    guard let id, let engine = interactor.engine else { return Defaults.fallbackSize }

    let currentLeft: Float = (try? engine.block.get(id, property: .key(.backgroundColorPaddingLeft))) ?? 0
    let currentRight: Float = (try? engine.block.get(id, property: .key(.backgroundColorPaddingRight))) ?? 0
    let width: Float = (try? Float(engine.block.getFrameWidth(id))) ?? Defaults.fallbackSize

    return max(width, currentLeft, currentRight)
  }

  private var maxCornerRadius: Float {
    guard let id, let engine = interactor.engine else { return Defaults.fallbackRadius }

    let currentRadius: Float = (try? engine.block.get(id, property: .key(.backgroundColorCornerRadius))) ?? 0
    let width: Float = (try? Float(engine.block.getFrameWidth(id))) ?? Defaults.fallbackSize
    let height: Float = (try? Float(engine.block.getFrameHeight(id))) ?? Defaults.fallbackSize

    let maxCornerRadius: Float = if width > height {
      height / 2 + maxVerticalPadding
    } else {
      width / 2 + maxHorizontalPadding
    }

    return max(maxCornerRadius, currentRadius)
  }

  // MARK: - View

  var body: some View {
    List {
      if interactor.supportsBackground(id) {
        Section {
          BackgroundColorOptions()
        } header: {
          Text(.imgly.localized("ly_img_editor_sheet_text_background_label_color"))
        }

        if isEnabled {
          paddingControls
          cornerRadiusControl
        }
      }
    }
  }

  private var paddingControls: some View {
    Group {
      Section {
        PropertySlider<Float>(
          .imgly.localized("ly_img_editor_sheet_text_background_label_vertical_padding"),
          in: 0 ... maxVerticalPadding,
          property: .key(.backgroundColorPaddingTop),
          setter: backgroundVerticalPaddingSetter,
          getter: backgroundVerticalPaddingGetter
        )
      } header: {
        Text(.imgly.localized("ly_img_editor_sheet_text_background_label_vertical_padding"))
      }

      Section {
        PropertySlider<Float>(
          .imgly.localized("ly_img_editor_sheet_text_background_label_horizontal_padding"),
          in: 0 ... maxHorizontalPadding,
          property: .key(.backgroundColorPaddingLeft),
          setter: backgroundHorizontalPaddingSetter,
          getter: backgroundHorizontalPaddingGetter
        )
      } header: {
        Text(.imgly.localized("ly_img_editor_sheet_text_background_label_horizontal_padding"))
      }
    }
  }

  private var cornerRadiusControl: some View {
    Section {
      PropertySlider<Float>(
        .imgly.localized("ly_img_editor_sheet_text_background_label_round_corners"),
        in: 0 ... maxCornerRadius,
        property: .key(.backgroundColorCornerRadius)
      )
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_text_background_label_round_corners"))
    }
  }
}

// MARK: - Property Getters/Setters

private let backgroundVerticalPaddingGetter: Interactor.PropertyGetter<Float> = { engine, id, propertyBlock, _ in
  let top: Float = try engine.block.get(id, propertyBlock, property: .key(.backgroundColorPaddingTop))
  let bottom: Float = try engine.block.get(id, propertyBlock, property: .key(.backgroundColorPaddingBottom))
  return min(top, bottom)
}

private let backgroundVerticalPaddingSetter: Interactor
  .PropertySetter<Float> = { engine, blocks, propertyBlock, _, value, completion in
    let changed = try blocks.filter {
      let currentTop: Float = try engine.block.get($0, propertyBlock, property: .key(.backgroundColorPaddingTop))
      let currentBottom: Float = try engine.block.get($0, propertyBlock,
                                                      property: .key(.backgroundColorPaddingBottom))
      return currentTop != value || currentBottom != value
    }

    try changed.forEach {
      try engine.block.set($0, propertyBlock, property: .key(.backgroundColorPaddingTop), value: value)
      try engine.block.set($0, propertyBlock, property: .key(.backgroundColorPaddingBottom), value: value)
    }

    let didChange = !changed.isEmpty
    return try (completion?(engine, blocks, didChange) ?? false) || didChange
  }

private let backgroundHorizontalPaddingGetter: Interactor
  .PropertyGetter<Float> = { engine, id, propertyBlock, _ in
    let left: Float = try engine.block.get(id, propertyBlock, property: .key(.backgroundColorPaddingLeft))
    let right: Float = try engine.block.get(id, propertyBlock, property: .key(.backgroundColorPaddingRight))
    return min(left, right)
  }

private let backgroundHorizontalPaddingSetter: Interactor
  .PropertySetter<Float> = { engine, blocks, propertyBlock, _, value, completion in
    let changed = try blocks.filter {
      let currentLeft: Float = try engine.block.get($0, propertyBlock, property: .key(.backgroundColorPaddingLeft))
      let currentRight: Float = try engine.block.get($0, propertyBlock, property: .key(.backgroundColorPaddingRight))
      return currentLeft != value || currentRight != value
    }

    try changed.forEach {
      try engine.block.set($0, propertyBlock, property: .key(.backgroundColorPaddingLeft), value: value)
      try engine.block.set($0, propertyBlock, property: .key(.backgroundColorPaddingRight), value: value)
    }

    let didChange = !changed.isEmpty
    return try (completion?(engine, blocks, didChange) ?? false) || didChange
  }

// MARK: - Background Color Options

struct BackgroundColorOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    ColorOptions(
      title: "Color",
      isEnabled: interactor.bind(id, property: .key(.backgroundColorEnabled), default: false),
      color: interactor.bind(
        id,
        property: .key(.backgroundColorColor),
        default: .imgly.black,
        completion: Interactor.Completion.set(
          property: .key(.backgroundColorEnabled),
          value: true,
        ),
      ),
      addUndoStep: interactor.addUndoStep,
      style: .fill,
    )
    .labelStyle(.iconOnly)
    .buttonStyle(.borderless)
  }
}
