import SwiftUI

@MainActor
public protocol AssetLibraryContent {
  var id: Int { get }
  var sources: [AssetLoader.SourceData] { get }
  var view: AnyView { get }

  func debugPrint(_ level: Int)
}

public extension AssetLibraryContent {
  var isEmpty: Bool { sources.isEmpty }
}

struct AssetLibraryContent_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
