@_spi(Internal) import IMGLYEditor
@_spi(Internal) import IMGLYCoreUI

final class DesignInteractorBehavior: InteractorBehavior {
  func rootBottomBarItems(_: InteractorContext) throws -> [RootBottomBarItem] {
    [
      .addElements,
      .addFromPhotoRoll,
      .addFromCamera(systemCamera: true),
      .addImage,
      .addText,
      .addShape,
      .addSticker
    ]
  }
}

extension InteractorBehavior where Self == DesignInteractorBehavior {
  static var design: Self { Self() }
}
