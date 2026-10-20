import SwiftUI

enum CameraMenuKind: Hashable { case timer, layout }

struct CameraMenuAnchorKey: PreferenceKey {
  static let defaultValue: [CameraMenuKind: Anchor<CGRect>] = [:]

  static func reduce(value: inout [CameraMenuKind: Anchor<CGRect>],
                     nextValue: () -> [CameraMenuKind: Anchor<CGRect>]) {
    value.merge(nextValue(), uniquingKeysWith: { _, new in new })
  }
}

struct CameraMenuOverlay: View {
  @EnvironmentObject private var camera: CameraModel
  @Environment(\.cameraRotation) private var rotation
  let anchors: [CameraMenuKind: Anchor<CGRect>]

  var body: some View {
    if let menu = camera.activeMenu, let anchor = anchors[menu] {
      GeometryReader { geometry in
        let bounds = geometry[anchor]
        let rows = menu == .timer ? CountdownMode.allCases.count : camera.layoutModeMenuOptions.count
        let size = CGSize(width: 240, height: CGFloat(rows * 48))
        let rotatedSize = rotation.orientation.isLandscape ? CGSize(width: size.height, height: size.width) : size
        Color.clear.contentShape(Rectangle()).onTapGesture { camera.activeMenu = nil }
        let position = position(anchor: bounds, size: rotatedSize, available: geometry.size)
        CameraPositionTransitionView(position: position) { position in
          menuContent(menu)
            .frame(width: size.width)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 12)
            .cameraRotated()
            .position(position)
        }
      }
    }
  }

  private func position(anchor: CGRect, size: CGSize, available: CGSize) -> CGPoint {
    let point = switch rotation.orientation {
    case .portrait: CGPoint(x: anchor.maxX + size.width / 2, y: anchor.midY)
    case .landscapeLeft: CGPoint(x: anchor.midX, y: anchor.maxY + size.height / 2)
    case .upsideDown: CGPoint(x: anchor.minX - size.width / 2, y: anchor.midY)
    case .landscapeRight: CGPoint(x: anchor.midX, y: anchor.minY - size.height / 2)
    }
    return CGPoint(x: min(max(point.x, size.width / 2 + 12), available.width - size.width / 2 - 12),
                   y: min(max(point.y, size.height / 2 + 12), available.height - size.height / 2 - 12))
  }

  private func menuContent(_ menu: CameraMenuKind) -> some View {
    VStack(spacing: 0) {
      switch menu {
      case .timer:
        ForEach(CountdownMode.allCases, id: \.rawValue) { mode in
          row(title: mode.name, icon: mode.image, selected: camera.countdownMode == mode) {
            camera.countdownMode = mode
          }
        }
      case .layout:
        ForEach(camera.layoutModeMenuOptions) { option in
          row(title: option.label, icon: option.icon, selected: camera.cameraMode.layoutMode == option.tag) {
            if camera.cameraMode.isReaction {
              camera.reactionsCameraModeBinding.wrappedValue = option.tag
            } else {
              camera.dualCameraModeBinding.wrappedValue = option.tag
            }
          }
        }
      }
    }
  }

  private func row(title: LocalizedStringResource, icon: Image, selected: Bool,
                   action: @escaping () -> Void) -> some View {
    Button {
      action()
      camera.activeMenu = nil
      HapticsHelper.shared.cameraSelectFeature()
    } label: {
      HStack(spacing: 12) {
        icon.frame(width: 24)
        Text(title)
        Spacer()
        if selected {
          Image(systemName: "checkmark")
        }
      }
      .padding(.horizontal, 16)
      .frame(minHeight: 48)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? [.isSelected] : [])
  }
}
