import Foundation
@_spi(Internal) import IMGLYCoreUI

struct SheetModel: IdentifiableByHash, Localizable {
  var mode: SheetMode
  var type: InternalSheetType

  init(_ mode: SheetMode, _ type: InternalSheetType) {
    self.mode = mode
    self.type = type
  }

  var description: String {
    "\(String(describing: mode)) \(String(describing: type))"
  }
}
