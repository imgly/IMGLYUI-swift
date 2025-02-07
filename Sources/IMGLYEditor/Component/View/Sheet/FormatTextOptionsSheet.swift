import SwiftUI

struct FormatTextOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet("Format") {
      TextFormatOptions()
    }
  }
}
