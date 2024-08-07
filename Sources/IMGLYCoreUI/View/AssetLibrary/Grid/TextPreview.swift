import IMGLYEngine
import SwiftUI

/// A list of text assets for preview.
public struct TextPreview: View {
  /// Creates a list of text assets for preview.
  public init() {}

  public var body: some View {
    TextList { _ in
      Message.noElements
    }
    .imgly.assetGrid(edges: [.leading, .trailing])
    .imgly.assetGrid(maxItemCount: 3)
    .imgly.assetGridPlaceholderCount { _, maxItemCount in
      maxItemCount
    }
    .imgly.assetGrid(messageTextOnly: true)
  }
}

struct TextPreview_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
