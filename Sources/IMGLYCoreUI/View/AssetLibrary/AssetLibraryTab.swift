import IMGLYCore
import SwiftUI

public struct AssetLibraryTab<Label: View>: View {
  private let title: String
  @AssetLibraryBuilder private let content: () -> AssetLibraryContent
  @ViewBuilder private let label: (_ title: LocalizedStringKey) -> Label

  public init(_ title: String,
              @AssetLibraryBuilder content: @escaping () -> AssetLibraryContent,
              @ViewBuilder label: @escaping (_ title: LocalizedStringKey) -> Label) {
    self.title = title
    self.content = content
    self.label = label
  }

  var localizedTitle: LocalizedStringKey { .init(title) }

  public var body: some View {
    AssetLibraryTabView(title) {
      content().view
    } label: { title in
      label(title)
    }
    #if DEBUG
//    .onAppear {
//      print("Tab", title)
//      content().debugPrint(1)
//    }
    #endif
  }
}

struct AssetLibraryTab_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
