import IMGLYEngine
import SwiftUI

/// A grid of audio assets.
public struct AudioGrid<Empty: View, First: View>: View {
  @ViewBuilder private let empty: (_ search: String) -> Empty
  @ViewBuilder private let first: () -> First

  /// Creates a grid of audio assets.
  /// - Parameters:
  ///   - empty: A view to display when the grid is empty.
  ///   - first: A view that is displayed before the first asset.
  public init(@ViewBuilder empty: @escaping (_ search: String) -> Empty = { _ in Message.noElements },
              @ViewBuilder first: @escaping () -> First = { EmptyView() }) {
    self.empty = empty
    self.first = first
  }

  public var body: some View {
    AudioList(empty: empty, first: first)
      .imgly.assetGridPlaceholderCount { state, _ in
        state == .loading ? 3 : 0
      }
  }
}

struct AudioGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
