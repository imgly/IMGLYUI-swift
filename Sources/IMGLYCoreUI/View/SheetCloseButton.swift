import SwiftUI

/// A modal-sheet close button ("✕") for a navigation-bar toolbar.
///
/// On iOS 26+ (Liquid Glass), this renders a plain `xmark` using the system toolbar button style,
/// as the toolbar supplies the circular glass background. Using a filled glyph would double the glass ring,
/// while `.borderless` shrinks the tap target. Legacy/pre-iOS 26 retains the filled-circle glyph at `.title2`
/// with `.borderless`.
struct SheetCloseButton: View {
  let title: LocalizedStringResource
  let action: () -> Void

  var body: some View {
    let button = Button(action: action) {
      Label {
        Text(title)
      } icon: {
        if #available(iOS 26.0, *), !usesLegacyDesign {
          Image(systemName: "xmark")
            .foregroundColor(.primary)
        } else {
          Image(systemName: "xmark.circle.fill")
            .font(.title2)
            .foregroundColor(.secondary)
        }
      }
      .symbolRenderingMode(.hierarchical)
    }

    if #available(iOS 26.0, *), !usesLegacyDesign {
      button
    } else {
      button.buttonStyle(.borderless)
    }
  }
}
