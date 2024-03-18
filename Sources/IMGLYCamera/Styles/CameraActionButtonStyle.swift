import SwiftUI

/// Custom button style with background blur and optional custom background shape.
struct CameraActionButtonStyle: ButtonStyle {
  enum Style {
    case `default`
    case delete
  }

  let style: Style

  @ScaledMetric var width: Double = 48
  @ScaledMetric var deleteBackgroundWidth: Double = 54
  @ScaledMetric var deleteBackgroundHeight: Double = 36
  @ScaledMetric var deleteBackgroundIconOffset: Double = 6

  func makeBody(configuration: Configuration) -> some View {
    ZStack {
      switch style {
      case .default:
        ZStack {
          Group {
            Circle()
              .fill(.regularMaterial)
            Circle()
              .fill(.tint)
              .opacity(configuration.isPressed ? 1 : 0)
              .animation(configuration.isPressed ? nil : .linear, value: configuration.isPressed)
          }
          .frame(width: width)
        }
      case .delete:
        ZStack {
          Group {
            CameraActionDeleteShape()
              .fill(.regularMaterial)
            CameraActionDeleteShape()
              .fill(.tint)
              .opacity(configuration.isPressed ? 1 : 0)
              .animation(configuration.isPressed ? nil : .linear, value: configuration.isPressed)
          }
          .frame(width: deleteBackgroundWidth, height: deleteBackgroundHeight)
        }
      }
    }
    .overlay {
      configuration.label
        .font(.title2)
        .foregroundColor(.white)
        .fontWeight(.medium)
        .offset(x: style == .delete ? deleteBackgroundIconOffset : 0)
    }
    .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 4)
    .padding(20)
    .contentShape(Rectangle())
    .padding(-20)
  }
}
