import IMGLYCore
import SwiftUI

/// A grid of audio assets with an upload button.
public struct AudioUploadGrid: View {
  /// Creates a grid of audio assets with an upload button.
  public init() {}

  @State private var showFileImporter = false

  @ViewBuilder var firstAddButton: some View {
    Button {
      showFileImporter.toggle()
    } label: {
      HStack(spacing: 0) {
        ZStack {
          GridItemBackground()
            .aspectRatio(1, contentMode: .fit)
          Image(systemName: "plus")
            .imageScale(.large)
        }
        .padding(.trailing, 16)
        Text(.imgly.localized("ly_img_editor_asset_library_button_add"))
          .font(.caption.weight(.medium))
        Spacer()
      }
      .frame(height: 48)
    }
    .tint(.primary)
  }

  public var body: some View {
    AudioGrid { _ in
      UploadGridAddButton(showUploader: $showFileImporter)
    } first: {
      firstAddButton
    }
    .imgly.assetFileUploader(isPresented: $showFileImporter, allowedContentTypes: [.audio])
  }
}

struct AudioUploadGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
