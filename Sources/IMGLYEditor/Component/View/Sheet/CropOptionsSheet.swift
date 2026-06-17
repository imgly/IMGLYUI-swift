import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct CropOptionsSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  let sources: [String]

  // Baseline for `canResetCrop`. Re-captured after a manual Reset because the
  // engine recomputes crop translation from the block frame on every `resetCrop`.
  @State private var initialCropTranslationX: Float = 0
  @State private var initialCropTranslationY: Float = 0

  var body: some View {
    CustomizableTitledSheet(.imgly.localized("ly_img_editor_sheet_crop_title")) {
      CropOptions(sources: sources)
    } leading: {
      // Do not use ActionButton here as placing it inside toolbar
      // will hide the title of the label.
      let action = Action.resetCrop
      Button {
        interactor.actionButtonTapped(for: action)
        captureInitialCropTranslation()
      } label: {
        HStack {
          if let imageName = action.imageName {
            if action.isSystemImage {
              Image(systemName: imageName)
            } else {
              Image(imageName, bundle: .module)
            }
          }
          Text(action.localizedStringResource)
        }
      }
      .disabled(!interactor.canResetCrop(
        id,
        initialCropTranslationX: initialCropTranslationX,
        initialCropTranslationY: initialCropTranslationY,
      ))
      .tint(.primary)
    }
    .ignoresSafeArea(.keyboard)
    .task(id: id) {
      captureInitialCropTranslation()
    }
  }

  private func captureInitialCropTranslation() {
    guard let id, let engine = interactor.engine, engine.block.isValid(id) else { return }
    do {
      initialCropTranslationX = try engine.block.getCropTranslationX(id)
      initialCropTranslationY = try engine.block.getCropTranslationY(id)
    } catch {}
  }
}
