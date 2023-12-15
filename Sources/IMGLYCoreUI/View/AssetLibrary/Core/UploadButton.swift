import SwiftUI

public struct UploadButton: View {
  private let media: [MediaType]

  public init(media: [MediaType]) {
    self.media = media
  }

  public var body: some View {
    UploadMenu(media: media) {
      UploadAddLabel()
    }
  }
}

struct UploadButton_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
