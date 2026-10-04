import SwiftUI

struct CameraRotation: Equatable {
  var orientation = CameraOrientation.portrait
  var angle: Double = 0
}

extension EnvironmentValues {
  @Entry var cameraRotation: CameraRotation = .init()
}

/// Measures the unrotated content with swapped constraints before rotating it around its center.
struct CameraRotationLayout: Layout {
  var sideways: Bool

  private func contentProposal(_ proposal: ProposedViewSize) -> ProposedViewSize {
    sideways ? ProposedViewSize(width: proposal.height, height: proposal.width) : proposal
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
    guard let content = subviews.first else { return .zero }
    let size = content.sizeThatFits(contentProposal(proposal))
    return sideways ? CGSize(width: size.height, height: size.width) : size
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
    subviews.first?.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center,
                          proposal: contentProposal(proposal))
  }
}

private struct CameraRotationModifier: ViewModifier {
  @Environment(\.cameraRotation) private var rotation
  let measuresRotation: Bool

  func body(content: Content) -> some View {
    if measuresRotation {
      CameraRotationLayout(sideways: rotation.orientation.isLandscape) {
        rotated(content)
      }
    } else {
      rotated(content)
    }
  }

  private func rotated(_ content: Content) -> some View {
    content.rotationEffect(.degrees(rotation.angle))
      .animation(.easeInOut(duration: 0.2), value: rotation.angle)
  }
}

extension View {
  func cameraRotated() -> some View {
    modifier(CameraRotationModifier(measuresRotation: true))
  }

  func cameraRotationEffect() -> some View {
    modifier(CameraRotationModifier(measuresRotation: false))
  }
}

/// Controls that change their screen position move only while hidden; centered content rotates in place.
struct CameraPositionedView<Content: View>: View {
  private struct Placement: Equatable {
    let alignment: Alignment
    let sideways: Bool
  }

  @Environment(\.cameraRotation) private var rotation
  let alignment: Alignment
  @ViewBuilder var content: () -> Content

  var body: some View {
    let placement = Placement(alignment: alignment, sideways: rotation.orientation.isLandscape)
    CameraPositionTransitionView(position: placement) { placement in
      content()
        .cameraRotated()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: placement.alignment)
    }
  }
}
