import SwiftUI

struct FilterOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet("Filter") {
      FilterOptions()
    }
  }
}
