import SwiftUI

struct VideoSheet: View {
  @EnvironmentObject private var interactor: Interactor

  private var sheet: SheetModel { interactor.sheet.model }

  var body: some View {
    BottomSheet {
      switch sheet.mode {
      case .volume:
        VolumeOptions()
      case .crop:
        CropOptions()
      case .fillAndStroke:
        FillAndStrokeOptions()
      case .layer:
        LayerOptions()
      case .adjustments:
        AdjustmentsOptions()
      case .filter:
        FilterOptions()
      case .blur:
        BlurOptions()
      case .effect:
        FXEffectOptions()
      case .reorder:
        ReorderOptions()
      default: EmptyView()
      }
    }
  }
}

struct VideoSheet_Previews: PreviewProvider {
  static var previews: some View {
    EmptyView()
  }
}
