import SwiftUI

struct StickerSheet: View {
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

struct StickerSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.add, .sticker))
  }
}
