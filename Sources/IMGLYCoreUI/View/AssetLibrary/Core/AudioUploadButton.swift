import IMGLYCore
import SwiftUI

/// A button to open a file import dialog for audio files that are added to an asset source.
public struct AudioUploadButton: View {
  /// Creates a button to add audio files to an asset source.
  public init() {}

  @State private var showFileImporter = false

  public var body: some View {
    Button {
      showFileImporter.toggle()
    } label: {
      UploadAddLabel()
    }
    .imgly.assetFileUploader(isPresented: $showFileImporter, allowedContentTypes: [.audio])
  }
}

struct AudioUploadButton_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
