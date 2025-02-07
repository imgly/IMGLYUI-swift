import SwiftUI

struct EffectOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet("Effect") {
      FXEffectOptions()
    }
  }
}
