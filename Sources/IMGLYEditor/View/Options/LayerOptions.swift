@_spi(Internal) import IMGLYCore
@_spi(Internal) import enum IMGLYCoreUI.BlendMode
import SwiftUI

struct LayerOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @ViewBuilder var layerButtons: some View {
    HStack(spacing: 8) {
      Group {
        ActionButton(.toTop)
        ActionButton(.up)
      }
      .disabled(!interactor.canBringForward(id))
      Group {
        ActionButton(.down)
        ActionButton(.toBottom)
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
        if interactor.hasOpacity(id) {
          Section("Opacity") {
            PropertySlider<Float>("Opacity", in: 0 ... 1, property: .key(.opacity))
          }
        }
      }
      if interactor.isAllowed(id, scope: .layerBlendMode) {
        if interactor.hasBlendMode(id) {
          Section {
            PropertyNavigationLink<BlendMode>("Blend Mode", property: .key(.blendMode))
          }
        }
      }
      if interactor.isAllowed(id, .toTop) {
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
    defaultPreviews(sheet: .init(.layer, .image))
  }
}
