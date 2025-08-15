@_spi(Internal) import IMGLYCore
import IMGLYCoreUI
import SwiftUI

struct FeaturesMenuView: View {
  @Environment(\.layoutDirection) private var layoutDirection

  @EnvironmentObject var camera: CameraModel

  @State private var hasTransientLabel = true
  @State private var transientLabelTimer: Timer?

  private let labelDisappearInterval: TimeInterval = 3
  var allowModeSwitching: Bool { camera.configuration.allowModeSwitching }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Group {
        countdownButton()
        switch camera.cameraMode {
        case .standard:
          if allowModeSwitching {
            dualCameraButton()
          }
        case .dualCamera:
          dualCameraButton()
        case .reaction:
          reactionsButton()
        }
      }
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            showTransientLabels()
          }
      )
      .menuOrder(.fixed)
      .transition(.offset(x: -20).combined(with: .opacity))
    }
    .padding(.leading, 12)
    .onAppear {
      showTransientLabels()
    }
  }

  private func showTransientLabels() {
    hasTransientLabel = true
    transientLabelTimer?.invalidate()
    transientLabelTimer = Timer.scheduledTimer(
      withTimeInterval: labelDisappearInterval,
      repeats: false
    ) { _ in
      hasTransientLabel = false
    }
  }
}

extension FeaturesMenuView {
  @ViewBuilder func countdownButton() -> some View {
    Menu {
      Picker(selection: $camera.countdownMode) {
        ForEach(CountdownMode.allCases, id: \.rawValue) { mode in
          if mode == .disabled {
            Divider()
          }
          Label {
            Text(mode.name)
          } icon: {
            mode.image
          }
          .tag(mode)
        }
      } label: {
        Text(.imgly.localized("ly_img_camera_button_timer"))
      }
      .pickerStyle(.inline)

    } label: {
      FeatureLabelView(
        text: camera.countdownMode == .disabled ? .imgly.localized("ly_img_camera_button_timer") : camera.countdownMode
          .name,
        image: camera.countdownMode.image,
        isSelected: camera.countdownMode != .disabled,
        hasLabel: hasTransientLabel
      )
    }
  }

  @ViewBuilder func dualCameraButton() -> some View {
    if camera.isMultiCamSupported {
      Menu {
        Picker(selection: camera.dualCameraModeBinding) {
          ForEach(camera.layoutModeMenuOptions) { mode in
            if mode == camera.layoutModeMenuOptions.last, allowModeSwitching {
              Divider()
            }
            Label {
              Text(mode.label)
            } icon: {
              mode.icon
            }
            .tag(mode.tag)
          }
        } label: {
          Text(.imgly.localized("ly_img_camera_button_dual_camera"))
        }
      } label: {
        FeatureLabelView(
          text: .imgly.localized("ly_img_camera_button_dual_camera"),
          image: camera.cameraMode.layoutMode?.image ?? Image("custom.camera.dual", bundle: .module),
          isSelected: camera.isDualCameraActive,
          hasLabel: hasTransientLabel
        )
      }
    }
  }

  @ViewBuilder func reactionsButton() -> some View {
    switch camera.cameraMode {
    case let .reaction(layout, _, _):
      Menu {
        Picker(selection: camera.reactionsCameraModeBinding) {
          ForEach(camera.layoutModeMenuOptions) { mode in
            if mode.tag == nil, allowModeSwitching {
              Divider()
            }
            mode.labelView
          }
        } label: {
          Text(.imgly.localized("ly_img_camera_button_reaction"))
        }
      } label: {
        FeatureLabelView(
          text: .imgly.localized("ly_img_camera_button_reaction"),
          image: layout.image,
          isSelected: true,
          hasLabel: hasTransientLabel
        )
      }
      .disabled(camera.hasRecordings)
      .opacity(camera.hasRecordings ? 0.6 : 1)
    default:
      Button {
        camera.pickReactionVideo()
      } label: {
        FeatureLabelView(
          text: "React",
          image: Image(systemName: "arrow.2.squarepath"),
          isSelected: false,
          hasLabel: hasTransientLabel
        )
      }
    }
  }
}

// MARK: - Model Extension Helpers

extension CameraModel {
  var isDualCameraActive: Bool {
    switch cameraMode {
    case .dualCamera: true
    default: false
    }
  }

  /// Creates a layout binding for the currently selected camera mode.
  ///
  /// Setting `nil` on the binding returns the camera to the `.standard` mode.
  ///
  /// - Parameter embed: A closure that embeds the selected layout mode into the current camera mode.
  /// - Returns: A binding for the selected camera layout mode.
  private func layoutBinding(
    _ embed: @escaping (CameraLayoutMode) -> CameraMode?
  ) -> Binding<CameraLayoutMode?> {
    .init { [unowned self] in
      cameraMode.layoutMode
    } set: { [unowned self] newMode in
      switch newMode {
      case let .some(layout):
        cameraMode = embed(layout) ?? .standard
      case .none:
        cameraMode = .standard
      }
    }
  }

  /// A binding for the dual camera layout mode.
  var dualCameraModeBinding: Binding<CameraLayoutMode?> {
    layoutBinding(CameraMode.dualCamera)
  }

  /// A binding for the reactions camera layout mode.
  var reactionsCameraModeBinding: Binding<CameraLayoutMode?> {
    layoutBinding { [unowned self] mode in
      guard case let .reaction(_, url, positionsSwapped) = cameraMode else { return nil }
      return .reaction(mode, video: url, positionsSwapped: positionsSwapped)
    }
  }

  /// Returns a list of options for the camera layout picker menu. Includes an item for "off" if allowed in the
  /// current configuration.
  var layoutModeMenuOptions: [PickerOption<CameraLayoutMode?>] {
    var options: [PickerOption<CameraLayoutMode?>] = CameraLayoutMode.allCases.map {
      PickerOption(label: $0.name, icon: $0.image, tag: $0)
    }
    if configuration.allowModeSwitching, isDualCameraActive {
      options.append(offItem)
    }
    return options
  }

  var offItem: PickerOption<CameraLayoutMode?> {
    PickerOption(label: .imgly.localized("ly_img_camera_layout_option_off"), icon: Image(systemName: "xmark"), tag: nil)
  }
}

extension PickerOption {
  var labelView: some View {
    Label {
      Text(label)
    } icon: {
      icon
    }
    .tag(tag)
  }
}

// MARK: - Preview

struct FeaturesMenu_Previews: PreviewProvider {
  static var previews: some View {
    let engineSettings = EngineSettings(license: "")
    Camera(engineSettings) { _ in }
  }
}
