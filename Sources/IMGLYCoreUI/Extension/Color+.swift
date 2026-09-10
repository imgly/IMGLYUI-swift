#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif
import SwiftUI

extension Color: HSBAConvertible {
  var hsba: HSBA? { HSBA(self) }
}

@_spi(Internal) public extension Color {
  #if os(iOS)
    private var nativeColor: UIColor { UIColor(self) }
  #elseif os(macOS)
    private var nativeColor: NSColor { NSColor(self) }
  #endif

  var asCGColor: CGColor {
    cgColor ?? nativeColor.cgColor
  }
}
