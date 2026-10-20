import SwiftUI

/// Retains the old placement and angle until a moving control has faded out.
struct CameraPositionTransition<Position: Equatable> {
  var position: Position
  var rotation: CameraRotation
  var isMoving = false

  func needsRepositioning(to position: Position, rotation: CameraRotation) -> Bool {
    self.position != position || (isMoving && self.rotation.orientation != rotation.orientation)
  }

  func displayedRotation(at position: Position, rotation: CameraRotation) -> CameraRotation {
    isMoving || self.position != position ? self.rotation : rotation
  }
}

/// Shares the fade-out, hidden placement update, and fade-in between controls and their menus.
struct CameraPositionTransitionView<Position: Equatable, Content: View>: View {
  private struct Target: Equatable {
    let position: Position
    let orientation: CameraOrientation
  }

  @Environment(\.cameraRotation) private var rotation
  let position: Position
  @ViewBuilder var content: (Position) -> Content

  @State private var displayed: CameraPositionTransition<Position>?
  @State private var opacity: Double = 1

  var body: some View {
    let transition = displayed ?? CameraPositionTransition(position: position, rotation: rotation)
    let isMoving = transition.isMoving || transition.position != position
    content(transition.position)
      .environment(\.cameraRotation, transition.displayedRotation(at: position, rotation: rotation))
      .transaction { transaction in
        // Rotation modifiers and inherited layout animations must not animate the hidden move.
        if isMoving {
          transaction.animation = nil
          transaction.disablesAnimations = true
        }
      }
      .opacity(opacity)
      .allowsHitTesting(!isMoving)
      .task(id: Target(position: position, orientation: rotation.orientation)) {
        await updatePlacement()
      }
  }

  private func updatePlacement() async {
    guard let previous = displayed else {
      displayed = CameraPositionTransition(position: position, rotation: rotation)
      return
    }
    let needsRepositioning = previous.needsRepositioning(to: position, rotation: rotation)
    if !needsRepositioning, !previous.isMoving {
      displayed?.rotation = rotation
      return
    }

    displayed?.isMoving = true
    if needsRepositioning {
      withAnimation(.easeInOut(duration: 0.3)) { opacity = 0 }
      do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
    }
    guard !Task.isCancelled else { return }
    displayed?.position = position
    displayed?.rotation = rotation
    withAnimation(.easeInOut(duration: 0.3)) { opacity = 1 }
    do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
    displayed?.isMoving = false
  }
}
