import SwiftUI

struct VideoSheet: View {
  @EnvironmentObject private var interactor: Interactor

  private var sheet: SheetModel { interactor.sheet.model }

  var body: some View {
    DismissableBottomSheet {
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
      case .shape:
        ShapeOptions()
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
