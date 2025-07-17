import SwiftUI

struct LayerOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet("Layer") {
      LayerOptions()
    }
  }
}
