import IMGLYCore
import SwiftUI

/// A grid of image assets.
public struct ImageGrid<Empty: View, First: View>: View {
  @ViewBuilder private let empty: (_ search: String) -> Empty
  @ViewBuilder private let first: () -> First

  /// Creates a grid of image assets.
  /// - Parameters:
  ///   - empty: A view to display when the grid is empty.
  ///   - first: A view that is displayed before the first asset.
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
