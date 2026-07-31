@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct TextOnPathItem: View {
  let asset: AssetLoader.Asset
  @Binding var selection: AssetSelection?
  @Binding var sheetState: EffectSheetState

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
    SelectableAssetItem(
      content: {
        ReloadableAsyncImage(asset: asset) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
        } onTap: {
          apply()
        }
      },
      title: title,
      selected: selected,
      properties: [],
      asset: asset,
      sheetState: $sheetState,
      hasCustomProperties: true,
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel(title)
    .accessibilityAddTraits(.isButton)
  }

  private func apply() {
    guard let engine = interactor.engine, let id else { return }
    Task {
      do {
        // Curve presets carry demo text for library insertion; the sheet only re-shapes the block.
        let text = try? engine.block.getString(id, property: Property.key(.textText).rawValue)
        try await engine.asset.applyToBlock(sourceID: asset.sourceID, assetResult: asset.result, block: id)
        if let text {
          try engine.block.setString(id, property: Property.key(.textText).rawValue, value: text)
        }
        // `setTextOnPath` (inside `applyToBlock`) clears the external-ref hint, so re-stamp it for the picker.
        try engine.block.setString(id, property: Property.key(.textPathExternalRef).rawValue, value: externalRef)
        interactor.addUndoStep()
      } catch {
        interactor.handleError(error)
      }
    }
  }
}
