import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct AdjustmentsOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @ViewBuilder var adjustmentOptions: some View {
    ForEach(Adjustment.allCases, id: \.rawValue) { adjustment in
      AdjustmentSlider(adjustment: adjustment, title: adjustment.localizedStringResource)
    }
  }

  var body: some View {
    List {
      adjustmentOptions
    }
  }
}

struct AdjustmentsOptions_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.libraryAdd {
      AssetLibrarySheet(content: .image)
    }, .image))
  }
}
