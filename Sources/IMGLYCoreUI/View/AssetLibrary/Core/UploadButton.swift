import SwiftUI

/// A button that presents a menu to open the photo roll, the camera, or a file import dialog for specific `media`
/// types to add assets to an asset source.
public struct UploadButton: View {
  private let media: [MediaType]

  /// Creates a button to add assets to an asset source.
  /// - Parameter media: The allowed media type(s).
  public init(media: [MediaType]) {
    self.media = media
  }

  public var body: some View {
    UploadMenu(media: media) {
      AddLabel()
    }
  }
}

struct UploadButton_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
