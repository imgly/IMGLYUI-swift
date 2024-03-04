@_spi(Internal) import IMGLYEditor
@_spi(Internal) import IMGLYCoreUI

final class DesignInteractorBehavior: InteractorBehavior {}

extension InteractorBehavior where Self == DesignInteractorBehavior {
  static var design: Self { Self() }
}
