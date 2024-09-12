import SwiftUI
@_spi(Internal) import IMGLYCoreUI
@_spi(Advanced) import SwiftUIIntrospect

// Sheet to be reused by content sheets like voiceover
// Can be reused to enable custom toolbar buttons or merge with bottom sheet
struct BottomSheet<Content: View>: View {
  // MARK: Properties

  @ViewBuilder let content: Content
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  private var sheet: SheetState { interactor.sheet }

  var title: LocalizedStringKey {
    switch sheet.mode {
    case .selectionColors, .font, .fontSize, .color:
      sheet.type.localizedStringKey
    default:
      sheet.mode.localizedStringKey(id, interactor)
    }
  }

  // MARK: Body

  var body: some View {
    NavigationView {
      content
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title)
    }
    .navigationViewStyle(.stack)
    .introspect(.navigationStack, on: .iOS(.v16...)) { navigationController in
      let navigationBar = navigationController.navigationBar
      // Fix cases when `.navigationBarTitleDisplayMode(.inline)` does not work.
      navigationBar.prefersLargeTitles = false
    }
  }
}
