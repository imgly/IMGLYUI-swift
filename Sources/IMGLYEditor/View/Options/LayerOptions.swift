@_spi(Internal) import IMGLYCore
@_spi(Internal) import enum IMGLYCoreUI.BlendMode
import SwiftUI

struct LayerOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @ViewBuilder var layerButtons: some View {
    VStack(spacing: 8) {
      HStack(spacing: 8) {
        ActionButton(.toFront)
        ActionButton(.bringForward)
      }
      .disabled(!interactor.canBringForward(id))
      HStack(spacing: 8) {
        ActionButton(.toBack)
        ActionButton(.sendBackward)
      }
      .disabled(!interactor.canBringBackward(id))
    }
    .tint(.primary)
    .buttonStyle(.option)
    .labelStyle(.tile(orientation: .vertical))
  }

  var body: some View {
    List {
      if interactor.isAllowed(id, scope: .layerOpacity) {
        if interactor.supportsOpacity(id) {
          Section {
            PropertySlider<Float>(
              .imgly.localized("ly_img_editor_sheet_layer_label_opacity"),
              in: 0 ... 1,
              property: .key(.opacity)
            )
          } header: {
            Text(.imgly.localized("ly_img_editor_sheet_layer_label_opacity"))
          }
        }
      }
      if interactor.isAllowed(id, scope: .layerBlendMode) {
        if interactor.supportsBlendMode(id) {
          Section {
            PropertyNavigationLink<BlendMode>(
              .imgly.localized("ly_img_editor_sheet_layer_label_blend_mode"),
              property: .key(.blendMode)
            )
          }
        }
      }
      if interactor.isAllowed(id, .toFront) {
        Section {
          EmptyView()
        } header: {
          layerButtons
        }
        .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
        .textCase(.none)
      }
      Section {
        if interactor.isAllowed(id, Action.duplicate) {
          ActionButton(.duplicate)
            .foregroundColor(.primary)
        }
        if interactor.isAllowed(id, Action.delete) {
          ActionButton(.delete)
            .foregroundColor(.red)
        }
      }
    }
  }
}

struct ArrangeOptions_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.layer(), .image))
  }
}
