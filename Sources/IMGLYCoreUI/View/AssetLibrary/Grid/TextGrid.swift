import IMGLYEngine
import SwiftUI

public struct TextGrid: View {
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
