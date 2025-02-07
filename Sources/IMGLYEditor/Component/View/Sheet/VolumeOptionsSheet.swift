import SwiftUI

struct VolumeOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet("Volume") {
      VolumeOptions()
    }
  }
}
