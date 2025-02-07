import SwiftUI

struct CropOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet("Crop") {
      CropOptions()
    }
  }
}
