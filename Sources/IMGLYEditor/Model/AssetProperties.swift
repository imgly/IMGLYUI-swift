import SwiftUI

struct AssetProperties {
  let title: String
  let backTitle: LocalizedStringResource
  let properties: [EffectProperty]
  /// The style to restore when leaving the properties page.
  var previousStyle: SheetStyle = .only(detent: .imgly.tiny)
}
