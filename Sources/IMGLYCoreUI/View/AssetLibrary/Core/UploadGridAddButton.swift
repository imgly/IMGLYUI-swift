import SwiftUI

struct UploadGridAddButton: View {
  @Binding var showUploader: Bool

  var body: some View {
    VStack(spacing: 30) {
      Message.noElements

      Button {
        showUploader.toggle()
      } label: {
        UploadAddLabel()
          .padding([.leading, .trailing], 40)
          .padding([.top, .bottom], 6)
      }
      .buttonStyle(.bordered)
      .font(.headline)
      .tint(.accentColor)
    }
  }
}

struct UploadGridAddButton_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
