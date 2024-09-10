import SwiftUI

struct TextSheet: View {
  @EnvironmentObject private var interactor: Interactor
  private var sheet: SheetModel { interactor.sheet.model }

  var body: some View {
    BottomSheet {
      switch sheet.mode {
      case .format: TextFormatOptions()
      case .fillAndStroke: FillAndStrokeOptions()
      case .layer: LayerOptions()
      default: EmptyView()
      }
    }
  }
}

struct TextSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.format, .text))
  }
}
