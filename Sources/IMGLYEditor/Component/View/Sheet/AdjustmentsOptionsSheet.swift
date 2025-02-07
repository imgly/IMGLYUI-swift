import SwiftUI

struct AdjustmentsOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet("Adjustments") {
      AdjustmentsOptions()
    }
  }
}
