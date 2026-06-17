@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

/// Options sheet that lets a text block follow an SVG baseline path.
struct TextOnPathOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @State private var sheetState: EffectSheetState = .selection

  private static let sourceID = "ly.img.text.presets"
  private static let curvesGroupID = "curves"

  // MARK: - Bindings

  /// Identifier is `nil` only when the block has no path (so None highlights); a manually edited path
  /// clears the external-ref hint, so it reads back empty — non-`nil`, matching neither None nor a tile.
  private static let selectionGetter: Interactor.RawGetter<AssetSelection> = { engine, block in
    guard try engine.block.getTextOnPath(block) != nil else {
      return AssetSelection()
    }
    let externalRef = try engine.block.getString(block, property: Property.key(.textPathExternalRef).rawValue)
    return AssetSelection(identifier: externalRef)
  }

  /// Only clears the path (None tile) — curve tiles apply their style preset via the asset API.
  private static let selectionSetter: Interactor.RawSetter<AssetSelection> = { engine, blocks, value, completion in
    guard value.identifier == nil else { return false }
    try blocks.forEach { try engine.block.setTextOnPath($0, svgPath: nil) }
    return try (completion?(engine, blocks, true) ?? true)
  }

  /// Ignores `nil` (a second tap on the selected button) so direction stays exclusive.
  private var directionBinding: Binding<Direction?> {
    let flipped = interactor.bind(id, default: false, getter: { engine, block in
      try engine.block.getTextOnPathFlipped(block)
    }, setter: { engine, blocks, value, completion in
      try blocks.forEach { try engine.block.setTextOnPathFlipped($0, flipped: value) }
      return try (completion?(engine, blocks, true) ?? true)
    })
    return Binding(
      get: { flipped.wrappedValue ? .reversed : .forward },
      set: { newValue in
        guard let newValue else { return }
        flipped.wrappedValue = (newValue == .reversed)
      },
    )
  }

  // MARK: - Body

  var body: some View {
    let selection = interactor.bind(id, getter: Self.selectionGetter, setter: Self.selectionSetter)
    let hasPath = selection.wrappedValue?.identifier != nil

    VStack(spacing: 0) {
      EffectOptions(
        selection: selection,
        item: { asset, _ in
          TextOnPathItem(
            asset: asset,
            selection: selection,
          )
        },
        identifier: { $0.result.id },
        sources: [.init(
          id: Self.sourceID,
          config: .init(groups: [Self.curvesGroupID]),
        )],
        sheetState: $sheetState,
      )
      .frame(height: hasPath ? 126 : nil, alignment: .top)

      if hasPath {
        List {
          pathPositionRow
          directionRow
          offsetSection
        }
      }
    }
  }

  @ViewBuilder private var pathPositionRow: some View {
    HStack {
      Text(.imgly.localized("ly_img_editor_sheet_text_on_path_label_path_position"))
      Spacer()
      HStack(spacing: 16) {
        let position: Binding<VerticalAlignment?> = interactor.bind(id, property: .key(.textVerticalAlignment))
        PropertyButton(property: .top, selection: position)
        PropertyButton(property: .center, selection: position)
        PropertyButton(property: .bottom, selection: position)
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
    }
  }

  @ViewBuilder private var directionRow: some View {
    HStack {
      Text(.imgly.localized("ly_img_editor_sheet_text_on_path_label_direction"))
      Spacer()
      HStack(spacing: 16) {
        PropertyButton(property: Direction.forward, selection: directionBinding)
        PropertyButton(property: Direction.reversed, selection: directionBinding)
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
    }
  }

  @ViewBuilder private var offsetSection: some View {
    Section {
      // The offset is a proportion of the path length.
      PropertySlider<Float>(
        .imgly.localized("ly_img_editor_sheet_text_on_path_label_offset"),
        in: -1 ... 1,
        property: .key(.textPathOffset),
      )
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_text_on_path_label_offset"))
    }
  }
}

// MARK: - Direction

private enum Direction: String, Labelable {
  case forward
  case reversed

  var localizationValue: String.LocalizationValue {
    switch self {
    case .forward: "ly_img_editor_sheet_text_on_path_direction_option_forward"
    case .reversed: "ly_img_editor_sheet_text_on_path_direction_option_reversed"
    }
  }

  var imageName: String? {
    switch self {
    case .forward: "arrow.clockwise"
    case .reversed: "arrow.counterclockwise"
    }
  }
}
