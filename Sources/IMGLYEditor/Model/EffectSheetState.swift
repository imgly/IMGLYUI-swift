import Foundation

enum EffectSheetState {
  case selection
  case properties(AssetProperties)

  var isProperties: Bool {
    if case .properties = self { return true }
    return false
  }
}
