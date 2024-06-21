import IMGLYEngine
import SwiftUI

/// A list of audio assets for preview.
public struct AudioPreview: View {
  /// Creates a list of audio assets for preview.
  public init() {}

  public var body: some View {
    AudioList { _ in
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

struct AudioPreview_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
