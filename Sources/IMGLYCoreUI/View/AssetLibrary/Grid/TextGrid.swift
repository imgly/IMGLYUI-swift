import IMGLYEngine
import SwiftUI

/// A grid of text assets.
public struct TextGrid: View {
  /// Creates a grid of text assets.
  public init() {}

  public var body: some View {
    TextList()
      .imgly.assetGridPlaceholderCount { state, _ in
        state == .loading ? 3 : 0
      }
  }
}

struct TextGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
