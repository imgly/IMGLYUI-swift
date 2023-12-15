import IMGLYEngine
import SwiftUI

public struct AudioGrid<Empty: View, First: View>: View {
  @ViewBuilder private let empty: (_ search: String) -> Empty
  @ViewBuilder private let first: () -> First

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
