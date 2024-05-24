import IMGLYEngine
import SwiftUI

/// A list of audio assets.
public struct AudioList<Empty: View, First: View>: View {
  @ViewBuilder private let empty: (_ search: String) -> Empty
  @ViewBuilder private let first: () -> First

  /// Creates a list of audio assets.
  /// - Parameters:
  ///   - empty: A view to display when the list is empty.
  ///   - first: A view that is displayed before the first asset.
  public init(@ViewBuilder empty: @escaping (_ search: String) -> Empty = { _ in Message.noElements },
              @ViewBuilder first: @escaping () -> First = { EmptyView() }) {
    self.empty = empty
    self.first = first
  }

  public var body: some View {
    AssetGrid { asset in
      AudioItem(asset: asset)
    } empty: {
      empty($0)
    } first: {
      first()
    }
    .imgly.assetGrid(axis: .vertical)
    .imgly.assetGrid(items: [GridItem(.flexible(), spacing: 8)])
    .imgly.assetGrid(spacing: 8)
    .imgly.assetGrid(padding: 16)
    .imgly.assetLoader()
  }
}

struct AudioList_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
