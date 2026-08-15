@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

/// A caption style preset cell. Tapping it applies the preset to the selected caption via
/// ``CaptionsInteractor/applyStylePreset(sourceID:assetResult:to:)``.
struct CaptionStyleItem: View {
  let asset: AssetLoader.Asset
  @Binding var selection: AssetSelection?

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  private var captionsInteractor: CaptionsInteractor {
    CaptionsInteractor(interactor)
  }

  private var selected: Bool {
    selection?.identifier == asset.result.id
  }

  private var title: String {
    asset.result.label ?? ""
  }

  var body: some View {
    SelectableEffectItem(title: title, selected: selected) {
      ReloadableAsyncImage(asset: asset) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
      } onTap: {
        apply()
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(title)
    .accessibilityAddTraits(.isButton)
  }

  private func apply() {
    guard let id else { return }
    Task {
      await captionsInteractor.applyStylePreset(sourceID: asset.sourceID, assetResult: asset.result, to: id)
    }
  }
}
