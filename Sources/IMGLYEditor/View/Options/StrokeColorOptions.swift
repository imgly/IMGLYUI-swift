@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct StrokeColorOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    if interactor.supportsStroke(id) {
      let strokeType: Binding<ColorFillType?> = interactor.bind(
        id,
        default: nil,
        getter: { engine, id in try engine.block.getStrokeFillType(id) },
        setter: strokeTypeSetter,
      )
      // Text, captions and lines take no stroke fill, so they keep the solid color row alone.
      if interactor.canPaintStrokeWithFill(id) {
        MenuPicker<[ColorFillType]>(
          title: .imgly.localized("ly_img_editor_sheet_fill_stroke_label_type"),
          data: ColorFillType.offered,
          selection: strokeType,
        )
        .accessibilityLabel("Stroke Type")
      }
      if strokeType.wrappedValue == .gradient {
        GradientOptions(propertyBlock: .strokeFill)
      } else {
        ColorOptions(title: .imgly.localized("ly_img_editor_sheet_fill_stroke_color_picker_title_stroke"),
                     isEnabled: interactor.bind(id, property: .key(.strokeEnabled), default: false),
                     color: interactor.bind(id, property: .key(.strokeColor), default: .imgly.black,
                                            setter: strokeColorSetter,
                                            completion: Interactor.Completion.set(property: .key(.strokeEnabled),
                                                                                  value: true)),
                     addUndoStep: interactor.addUndoStep,
                     style: .stroke)
          .accessibilityElement(children: .contain)
          .accessibilityLabel(Text(.imgly.localized("ly_img_editor_sheet_fill_stroke_color_picker_title_stroke")))
      }
    }
  }

  private let strokeTypeSetter: Interactor.RawSetter<ColorFillType?> = { engine, blocks, value, completion in
    guard let value else { return false }
    let changed = try blocks.filter { try engine.block.setStrokeFillType($0, value) }
    let didChange = !changed.isEmpty
    return try (completion?(engine, blocks, didChange) ?? false) || didChange
  }

  /// A solid color paints the stroke only while no fill paints it, so picking one removes the stroke fill.
  private let strokeColorSetter: Interactor.PropertySetter<CGColor> = { engine, blocks, _, property, color, done in
    var didChange = try engine.block.set(blocks, property: property, value: color)
    for block in blocks where try engine.block.removeStrokeFill(block) {
      didChange = true
    }
    return try (done?(engine, blocks, didChange) ?? false) || didChange
  }
}
