import SwiftUI

struct GroupSheet: View {
  @EnvironmentObject private var interactor: Interactor
  private var sheet: SheetModel { interactor.sheet.model }

  var body: some View {
    BottomSheet {
      switch sheet.mode {
      case .layer: LayerOptions()
      default: EmptyView()
      }
    }
  }
}

struct GroupSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.layer, .group))
  }
}
