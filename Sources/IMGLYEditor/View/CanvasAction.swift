import SwiftUI

struct CanvasAction<Action>: ViewModifier where Action: View {
  @EnvironmentObject private var interactor: Interactor

  let anchor: UnitPoint
  let topSafeAreaInset: CGFloat
  let bottomSafeAreaInset: CGFloat
  let isVisible: Bool

  @ViewBuilder let action: Action

  @GestureState private var isDragging = false
  @GestureState private var isMagnifying = false
  @GestureState private var isRotating = false

  private var showAction: Bool {
    interactor.isCanvasActionEnabled && !isInteracting && isVisible
  }

  private var isInteracting: Bool {
    isDragging || isMagnifying || isRotating
  }

  @Environment(\.layoutDirection) private var layoutDirection
  @State private var actionViewSize: CGSize = .zero

  /// Compute safe rect because `interactor.selection.boundingBox` does not contain the gizmos.
  private func safeRect(for rect: CGRect) -> CGRect {
    let rotation = interactor.rotationForSelection ?? 0
    let gizmoLength: CGFloat = 48
    let sin = sin(rotation)
    let cos = cos(rotation)
    let dx = -sin * gizmoLength
    let dy = cos * gizmoLength

    // Safe rect including gizmos
    var safeRect = CGRect(
      x: rect.minX + (dx > 0 ? 0 : dx),
      y: rect.minY + (dy > 0 ? 0 : dy),
      width: rect.width + abs(dx),
      height: rect.height + abs(dy)
    )

    // Shrink safe rect for some known anchors to keep the `action` centered
    switch anchor {
    case .top, .bottom:
      safeRect.origin.x = rect.origin.x
      safeRect.size.width = rect.size.width
    case .leading, .trailing:
      safeRect.origin.y = rect.origin.y
      safeRect.size.height = rect.size.height
    case .center:
      safeRect = rect
    default:
      break
    }

    return safeRect
  }

  private func anchor(for rect: CGRect, in screenSize: CGSize) -> CGPoint {
    let navbarHeight: CGFloat = topSafeAreaInset + 22.5
    let edgePadding: CGFloat = 10.0
    let actionViewSize = actionViewSize

    // Calculate initial anchor points
    let adjustedAnchorX = layoutDirection == .leftToRight ? anchor.x : 1 - anchor.x
    var x = rect.minX + (adjustedAnchorX * rect.width)
    var y = rect.minY + (anchor.y * rect.height)

    // Adjust y to avoid overlap with the navbar and the bottom edge
    let minY = navbarHeight + edgePadding + actionViewSize.height
    if y < minY {
      // Ensure the action view does not go beyond the screen's bottom edge
      if rect.maxY + actionViewSize.height + edgePadding + bottomSafeAreaInset > screenSize.height {
        y = minY
      } else {
        y = rect.maxY + actionViewSize.height / 2 + edgePadding
      }
    }

    // Adjust x to stay within the screen's left and right edges
    x = max(min(x, screenSize.width - edgePadding - actionViewSize.width / 2), edgePadding + actionViewSize.width / 2)
    return CGPoint(x: x, y: y)
  }

  private let viewDebugging = false

  @ViewBuilder func box(_ rect: CGRect, _ color: Color) -> some View {
    Color.clear
      .frame(width: rect.width, height: rect.height)
      .border(color)
      .position(x: rect.midX, y: rect.midY)
  }

  func body(content: Content) -> some View {
    ZStack {
      GeometryReader { geometry in
        content
          .onChange(of: isInteracting) { newValue in
            interactor.isGestureActive(newValue)
          }
        #if os(iOS)
          .simultaneousGesture(
            DragGesture(minimumDistance: 1).updating($isDragging) { _, state, _ in state = true }
          )
          .simultaneousGesture(
            MagnificationGesture().updating($isMagnifying) { _, state, _ in state = true }
          )
          .simultaneousGesture(
            RotationGesture().updating($isRotating) { _, state, _ in state = true }
          )
        #endif

        if let selection = interactor.selection {
          let rect = selection.boundingBox
          let safeRect = safeRect(for: rect)
          action
            .background(GeometryReader { geo -> Color in
              DispatchQueue.main.async {
                actionViewSize = geo.size
              }
              return Color.clear
            })
            .position(anchor(for: safeRect, in: geometry.size))
            .allowsHitTesting(showAction)
            .disabled(!showAction)
            .opacity(showAction ? 1 : 0)
            .clipped()

          if viewDebugging {
            box(rect, .red)
            box(safeRect, .green)
          }
        }
      }
    }
  }
}

struct CanvasAction_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
