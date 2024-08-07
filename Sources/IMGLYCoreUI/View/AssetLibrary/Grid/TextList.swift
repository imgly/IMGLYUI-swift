import IMGLYEngine
import SwiftUI

/// A list of text assets.
public struct TextList<Empty: View>: View {
  @ViewBuilder private let empty: (_ search: String) -> Empty

  /// Creates a list of text assets.
  /// - Parameter empty: A view to display when the list is empty.
  public init(@ViewBuilder empty: @escaping (_ search: String) -> Empty = { _ in Message.noElements }) {
    self.empty = empty
  }

  public var body: some View {
    AssetGrid { asset in
      TextItem(asset: asset)
    } empty: {
      empty($0)
    }
    .imgly.assetGrid(axis: .vertical)
    .imgly.assetGrid(items: [GridItem(.flexible(), spacing: 8)])
    .imgly.assetGrid(spacing: 8)
    .imgly.assetGrid(padding: 16)
    .imgly.assetLoader()
  }
}

struct TextList_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
