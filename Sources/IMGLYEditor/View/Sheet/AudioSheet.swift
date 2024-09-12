import SwiftUI

struct AudioSheet: View {
  @EnvironmentObject private var interactor: Interactor

  private var sheet: SheetModel { interactor.sheet.model }

  var body: some View {
    DismissableBottomSheet {
      switch sheet.mode {
      case .volume:
        VolumeOptions()
      default: EmptyView()
      }
    }
  }
}
