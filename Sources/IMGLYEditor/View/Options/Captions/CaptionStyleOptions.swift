@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

/// Caption style preset grid, fed by the `ly.img.caption.presets` asset source. A preset is applied to the
/// selected caption and the engine syncs it across the track, so cells apply directly and there is no
/// "None" tile. The highlight is read back from a marker the apply records on the caption track.
struct CaptionStyleOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @State private var sheetState: EffectSheetState = .selection

  private static let sourceID = "ly.img.caption.presets"

  private var captionsInteractor: CaptionsInteractor {
    CaptionsInteractor(interactor)
  }

  /// The highlight reads the applied-preset marker off the caption track (not the caption itself).
  private var selectionGetter: Interactor.RawGetter<AssetSelection> {
    let captionsInteractor = captionsInteractor
    return { _, _ in AssetSelection(identifier: captionsInteractor.appliedPresetIdentifier()) }
  }

  /// No-op: with no None tile the setter is never called (cells apply directly). Satisfies the shared binding.
  private static let selectionSetter: Interactor.RawSetter<AssetSelection> = { engine, blocks, _, completion in
    try (completion?(engine, blocks, false) ?? false)
  }

  var body: some View {
    let selection = interactor.bind(id, getter: selectionGetter, setter: Self.selectionSetter)
    EffectOptions(
      selection: selection,
      item: { asset, _ in
        CaptionStyleItem(asset: asset, selection: selection)
      },
      identifier: { $0.result.id },
      sources: [.init(id: Self.sourceID)],
      sheetState: $sheetState,
      showNoneItem: false,
    )
  }
}
