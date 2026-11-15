@_spi(Internal) import IMGLYCore
@_spi(Internal) import enum IMGLYCoreUI.StrokeStyle
import SwiftUI

struct StrokeOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @Binding var isEnabled: Bool

  /// The width is a length in the scene's design unit.
  private var designUnit: Interactor.DesignUnit {
    (try? interactor.engine?.scene.getDesignUnit()) ?? .px
  }

  /// The block's longer side, or the width when that is larger, so a loaded width is not cut to fit.
  private var maxWidth: Float {
    // The sheet shows no stroke without a selection, so the fallback only keeps the range valid.
    guard let id, let engine = interactor.engine else { return 1 }
    let width = (try? engine.block.getFrameWidth(id)) ?? 0
    let height = (try? engine.block.getFrameHeight(id)) ?? 0
    let strokeWidth = (try? engine.block.getStrokeWidth(id)) ?? 0
    return max(width, height, strokeWidth)
  }

  var body: some View {
    if interactor.supportsStroke(id) {
      StrokeColorOptions()
      if isEnabled {
        // No `Section` wrapper: this body already renders inside the
        // "Stroke" section `FillAndStrokeOptions` puts around it.
        // A stepper, not a slider, so the same width can be typed again on another block.
        PropertyStepper<Float>(
          .imgly.localized("ly_img_editor_sheet_fill_stroke_label_width"),
          in: 0 ... maxWidth,
          step: designUnit.inputStep,
          property: .key(.strokeWidth),
          unit: designUnit.abbreviation,
        )
        PropertyPicker<StrokeStyle>(
          .imgly.localized("ly_img_editor_sheet_fill_stroke_label_style"),
          property: .key(.strokeStyle),
        )
        // Position and Join pickers don't apply to a 1-D primitive.
        if !interactor.isLineOrigin(id) {
          PropertyPicker<StrokePosition>(
            .imgly.localized("ly_img_editor_sheet_fill_stroke_label_position"),
            property: .key(.strokePosition),
          )
          // Stroke position is fixed for text and captions (text-family blocks), as on text.
          .disabled(interactor.sheet.content == .text || interactor.sheet.content == .caption)
          PropertyPicker<StrokeJoin>(
            .imgly.localized("ly_img_editor_sheet_fill_stroke_label_join"),
            property: .key(.strokeCornerGeometry),
          )
        }
      }
    }
  }
}

struct StrokeOptions_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.fillStroke(), .shape))
  }
}
