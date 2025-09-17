import SwiftUI

class AssetLibrarySectionConfiguration: ObservableObject {
  @Published var isNavigationAllowed: Bool
  @Published var isSearchAllowed: Bool

  init(isNavigationAllowed: Bool = true, isSearchAllowed: Bool = true) {
    self.isNavigationAllowed = isNavigationAllowed
    self.isSearchAllowed = isSearchAllowed
  }
}
