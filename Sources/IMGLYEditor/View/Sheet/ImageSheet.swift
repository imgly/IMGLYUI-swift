import SwiftUI

struct ImageSheet: View {
  @EnvironmentObject private var interactor: Interactor
  private var sheet: SheetModel { interactor.sheet.model }

  var body: some View {
    BottomSheet {
      switch sheet.mode {
      case .crop: CropOptions()
      case .fillAndStroke: FillAndStrokeOptions()
      case .layer: LayerOptions()
      case .adjustments: AdjustmentsOptions()
      case .filter: FilterOptions()
      case .blur: BlurOptions()
      case .effect: FXEffectOptions()
      default: EmptyView()
      }
    }
  }
}

struct ImageSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.add, .image))
  }
}
