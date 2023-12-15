import UIKit

extension UIColor: HSBAConvertible {
  var hsba: HSBA? { HSBA(self) }
}

extension UIColor {
  convenience init(hsba: HSBA) {
    self.init(hue: hsba.hue, saturation: hsba.saturation, brightness: hsba.brightness, alpha: hsba.alpha)
  }
}
