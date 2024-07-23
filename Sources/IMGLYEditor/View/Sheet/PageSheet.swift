import IMGLYCoreUI
import SwiftUI

struct PageSheet: View {
  @EnvironmentObject private var interactor: Interactor

  private var sheet: SheetModel { interactor.sheet.model }

  var body: some View {
    DismissableBottomSheet {
      switch sheet.mode {
      case .crop: CropOptions()
      case .fillAndStroke: FillAndStrokeOptions()
      case .adjustments: AdjustmentsOptions()
      case .filter: FilterOptions()
      case .blur: BlurOptions()
      case .effect: FXEffectOptions()
      default: EmptyView()
      }
    }
  }
}

struct PageSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.fillAndStroke, .page))
  }
}
