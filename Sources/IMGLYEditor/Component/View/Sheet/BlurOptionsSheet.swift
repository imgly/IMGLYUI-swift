import SwiftUI

struct BlurOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet("Blur") {
      BlurOptions()
    }
  }
}
