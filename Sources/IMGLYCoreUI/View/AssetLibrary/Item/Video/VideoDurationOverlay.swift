import SwiftUI

struct VideoDurationOverlay: View {
  let duration: TimeInterval

  private var formattedDuration: String {
    let seconds = Int(duration.rounded())
    return "\(seconds)s"
  }

  var body: some View {
    Text(formattedDuration)
      .font(.caption2)
      .fontWeight(.medium)
      .foregroundColor(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .fill(Color.black.opacity(0.7)),
      )
      .padding(6)
  }
}
