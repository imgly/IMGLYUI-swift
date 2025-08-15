#if os(iOS)
  import MobileCoreServices
  import SwiftUI
  @_spi(Internal) import IMGLYCore

  @_spi(Internal) public extension IMGLY where Wrapped: View {
    /// Presents the image picker when `isPresented` is `true`
    /// - Parameters:
    ///   - isPresented: A binding to the boolean that will trigger the presentation
    ///   - media: An array that indicates the available media types
    ///   - onComplete: When an image has been selected, this will be called with the resulting URL to the file or an
    /// error
    func imagePicker(isPresented: Binding<Bool>, media: [MediaType] = [.image],
                     onComplete: @escaping MediaCompletion) -> some View {
      wrapped.background(ImagePickerView(isPresented: isPresented, media: media, onComplete: onComplete))
    }
  }

  private struct ImagePickerView: View {
    let isPresented: Binding<Bool>
    let media: [MediaType]
    let completion: MediaCompletion

    init(isPresented: Binding<Bool>, media: [MediaType], onComplete: @escaping MediaCompletion) {
      self.isPresented = isPresented
      self.media = media
      completion = onComplete
    }

    var body: some View {
      MediaView(isPresented: isPresented, source: .photoLibrary, media: media, completion: completion)
    }
  }
#endif
