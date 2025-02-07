import SwiftUI

struct ShapeOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet("Shape") {
      ShapeOptions()
    }
  }
}
