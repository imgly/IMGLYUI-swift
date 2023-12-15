import SwiftUI

struct AdjustmentsOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @ViewBuilder var adjustmentOptions: some View {
    ForEach(Adjustment.allCases, id: \.rawValue) { adjustment in
      AdjustmentSlider(adjustment: adjustment, title: .init(adjustment.rawValue))
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
    defaultPreviews(sheet: .init(.add, .image))
  }
}
