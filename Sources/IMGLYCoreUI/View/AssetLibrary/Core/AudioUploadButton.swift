import IMGLYCore
import SwiftUI

public struct AudioUploadButton: View {
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
