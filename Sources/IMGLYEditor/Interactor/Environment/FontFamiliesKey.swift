import SwiftUI

struct FontFamiliesKey: EnvironmentKey {
  static let defaultValue: [String]? = nil
}

extension EnvironmentValues {
  var imglyFontFamilies: [String]? {
    get { self[FontFamiliesKey.self] }
    set { self[FontFamiliesKey.self] = newValue }
  }
}
