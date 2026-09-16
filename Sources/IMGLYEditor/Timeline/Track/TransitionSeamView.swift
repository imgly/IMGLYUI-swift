import SwiftUI

struct TransitionSeamView: View {
  let hasTransition: Bool
  let isCompact: Bool
  let onTap: () -> Void

  var body: some View {
    if isCompact {
      Circle()
        .fill(.background)
        .frame(width: 10, height: 10)
        .shadow(radius: 2)
        .overlay(Circle().fill(.primary).frame(width: 6, height: 6))
    } else {
      Circle()
        .fill(.clear)
        .frame(width: 40, height: 40)
        .overlay {
          Circle()
            .fill(.background)
            .frame(width: 24, height: 24)
            .shadow(radius: 4)
            .overlay {
              if hasTransition {
                Image.imgly.transition
                  .resizable()
                  .scaledToFit()
                  .padding(6)
              } else {
                Image(systemName: "plus")
                  .resizable()
                  .scaledToFit()
                  .padding(6)
              }
            }
        }
        .contentShape(Circle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.imgly.localized(hasTransition
            ? "ly_img_editor_timeline_button_view_transition"
            : "ly_img_editor_timeline_button_add_transition")))
        .accessibilityAddTraits(.isButton)
    }
  }
}
