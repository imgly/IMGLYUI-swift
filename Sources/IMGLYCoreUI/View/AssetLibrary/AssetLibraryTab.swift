import IMGLYCore
import SwiftUI

/// A tab used in an ``AssetLibrary`` to display ``AssetLibraryContent``.
public struct AssetLibraryTab<Label: View>: View {
  private let title: LocalizedStringResource
  @AssetLibraryBuilder private let content: () -> AssetLibraryContent
  @ViewBuilder private let label: (_ title: LocalizedStringResource) -> Label

  /// Creates an asset library tab with asset library `content`.
  /// - Parameters:
  ///   - title: The title of the tab.
  ///   - content: The asset library content.
  ///   - label: The label of the tab. The `title` is passed to this closure.
  public init(_ title: LocalizedStringResource,
              @AssetLibraryBuilder content: @escaping () -> AssetLibraryContent,
              @ViewBuilder label: @escaping (_ title: LocalizedStringResource) -> Label) {
    self.title = title
    self.content = content
    self.label = label
  }

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
