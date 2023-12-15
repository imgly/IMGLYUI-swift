import Introspect
import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct BottomSheet<Content: View>: View {
  @ViewBuilder let content: Content

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  private var sheet: SheetState { interactor.sheet }

  var title: LocalizedStringKey {
    switch sheet.mode {
    case .options:
      return LocalizedStringKey("\(String(describing: sheet.type)) \(String(describing: sheet.mode))")
    case .selectionColors, .font, .fontSize, .color:
      return sheet.type.localizedStringKey
    default:
      return sheet.mode.localizedStringKey(id, interactor)
    }
  }

  var body: some View {
    NavigationView {
      content
        .navigationBarTitleDisplayMode(.inline)
        .introspectNavigationController { navigationController in
          let navigationBar = navigationController.navigationBar
          // Fix cases when `.navigationBarTitleDisplayMode(.inline)` does not work.
          navigationBar.prefersLargeTitles = false
        }
        .navigationTitle(title)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            SheetDismissButton()
              .buttonStyle(.borderless)
          }
        }
    }
    .navigationViewStyle(.stack)
  }
}

struct BottomSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.add, .image))
  }
}
