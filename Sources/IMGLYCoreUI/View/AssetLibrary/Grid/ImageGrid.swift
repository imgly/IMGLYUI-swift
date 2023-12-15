import IMGLYCore
import SwiftUI

public struct ImageGrid<Empty: View, First: View>: View {
  @ViewBuilder private let empty: (_ search: String) -> Empty
  @ViewBuilder private let first: () -> First

  public init(@ViewBuilder empty: @escaping (_ search: String) -> Empty = { _ in Message.noElements },
              @ViewBuilder first: @escaping () -> First = { EmptyView() }) {
    self.empty = empty
    self.first = first
  }

  public var body: some View {
    AssetGrid { asset in
      ImageItem(asset: asset)
    } empty: {
      empty($0)
    } first: {
      first()
    }
    .imgly.assetGrid(axis: .vertical)
    .imgly.assetGrid(items: [GridItem(.adaptive(minimum: 108, maximum: 152), spacing: 4)])
    .imgly.assetGrid(spacing: 4)
    .imgly.assetGrid(padding: 4)
    .imgly.assetGridPlaceholderCount { state, _ in
      state == .loading ? 3 : 0
    }
    .imgly.assetLoader()
  }
}

struct ImageGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
