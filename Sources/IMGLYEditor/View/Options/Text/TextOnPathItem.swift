@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct TextOnPathItem: View {
  let asset: AssetLoader.Asset
  @Binding var selection: AssetSelection?

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  private var externalRef: String {
    "\(asset.sourceID)|\(asset.result.id)"
  }

  private var selected: Bool {
    selection?.identifier == externalRef
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
    guard let engine = interactor.engine, let id else { return }
    Task {
      do {
        try await engine.asset.applyToBlock(sourceID: asset.sourceID, assetResult: asset.result, block: id)
        // `setTextOnPath` (inside `applyToBlock`) clears the external-ref hint, so re-stamp it for the picker.
        try engine.block.setString(id, property: Property.key(.textPathExternalRef).rawValue, value: externalRef)
        interactor.addUndoStep()
      } catch {
        interactor.handleError(error)
      }
    }
  }
}
