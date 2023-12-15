import SwiftUI

struct ShapeSheet: View {
  @EnvironmentObject private var interactor: Interactor
  private var sheet: SheetModel { interactor.sheet.model }

  var body: some View {
    BottomSheet {
      switch sheet.mode {
      case .options: ShapeOptions()
      case .fillAndStroke: FillAndStrokeOptions()
      case .layer: LayerOptions()
      default: EmptyView()
      }
    }
  }
}

struct ShapeSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.add, .shape))
  }
}
