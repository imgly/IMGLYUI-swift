import IMGLYCoreUI
import SwiftUI

struct PageSheet: View {
  @EnvironmentObject private var interactor: Interactor

  private var sheet: SheetModel { interactor.sheet.model }

  var body: some View {
    BottomSheet {
      switch sheet.mode {
      case .fillAndStroke: FillAndStrokeOptions()
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
