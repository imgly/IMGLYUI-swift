import SwiftUI
@_spi(Internal) import IMGLYCore

@_spi(Internal) public extension IMGLY where Wrapped: View {
  /// Presents the photos picker or (depreacted) image picker depending on `FeatureFlag.photosPicker` when `isPresented`
  /// is `true`
  /// - Parameters:
  ///   - isPresented: A binding to the boolean that will trigger the presentation
  ///   - media: An array that indicates the available media types
  ///   - onComplete: When an item has been selected, this will be called with the resulting URL to the file or an
  /// error
  @MainActor
  func photoRoll(isPresented: Binding<Bool>, media: [MediaType] = [.image],
                 maxSelectionCount: Int?, onComplete: @escaping MediaCompletion) -> some View {
    wrapped.modifier(PhotoRoll(isPresented: isPresented, media: media,
                               maxSelectionCount: maxSelectionCount, completion: onComplete))
  }
}

private struct PhotoRoll: ViewModifier {
  @Binding var isPresented: Bool
  let media: [MediaType]
  let maxSelectionCount: Int?
  let completion: MediaCompletion

  @Feature(.photosPicker) private var isPhotosPickerEnabled

  func body(content: Content) -> some View {
    if isPhotosPickerEnabled {
      content.imgly.photosPicker(
        isPresented: $isPresented,
        media: media,
        maxSelectionCount: maxSelectionCount,
        onComplete: completion,
      )
    } else {
      if maxSelectionCount != 1 {
        // swiftlint:disable:next redundant_discardable_let
        let _ =
          print(
            // swiftlint:disable:next line_length
            "`UIImagePickerController` does not support `maxSelectionCount` other than 1, falling back to single selection mode.",
          )
      }
      content.imgly.imagePicker(isPresented: $isPresented, media: media, onComplete: completion)
    }
  }
}
