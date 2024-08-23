@_spi(Internal) import IMGLYCore
import IMGLYCoreUI
import SwiftUI

struct FeaturesMenuView: View {
  @Environment(\.layoutDirection) private var layoutDirection

  @EnvironmentObject var camera: CameraModel

  @State private var hasTransientLabel = true
  @State private var transientLabelTimer: Timer?

  private let labelDisappearInterval: TimeInterval = 3

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Group {
        countdownButton()
        if camera.isMultiCamSupported {
          dualCameraButton()
        }
        if FeatureFlags.videoReactions {
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

// MARK: -

extension CameraModel {
  var isDualCameraActive: Bool {
    switch cameraMode {
    case .dualCamera: true
    default: false
    }
  }

  var dualCameraModeBinding: Binding<CameraLayoutMode?> {
    .init { [unowned self] in
      guard case let .dualCamera(layoutMode) = cameraMode else { return nil }
      return layoutMode
    } set: { [unowned self] newMode in
      switch newMode {
      case let .some(layout):
        cameraMode = .dualCamera(layout)
      case .none:
        cameraMode = .standard
      }
    }
  }

  var dualCameraModeMenuOptions: [PickerOption<CameraLayoutMode?>] {
    CameraLayoutMode.allCases.map {
      PickerOption(label: $0.name, icon: $0.image, tag: $0)
    } + [
      PickerOption(label: "Off", icon: Image(systemName: "xmark"), tag: nil),
    ]
  }
}

struct PickerOption<T>: Identifiable, Equatable where T: Hashable {
  var label: LocalizedStringKey
  var icon: Image
  var tag: T
  var id: T { tag }
}

extension FeaturesMenuView {
  @ViewBuilder func countdownButton() -> some View {
    Menu {
      Picker("Countdown Mode", selection: $camera.countdownMode) {
        ForEach(CountdownMode.allCases, id: \.rawValue) { mode in
          if mode == .disabled {
            Divider()
          }
          Text(mode.name)
            .tag(mode)
        }
      }
    } label: {
      FeatureLabelView(
        text: camera.countdownMode == .disabled ? "Timer" : camera.countdownMode.name,
        image: Image(systemName: "timer"),
        isSelected: camera.countdownMode != .disabled,
        hasLabel: hasTransientLabel
      )
    }
  }

  @ViewBuilder func dualCameraButton() -> some View {
    Menu {
      Picker("Dual Camera", selection: camera.dualCameraModeBinding) {
        ForEach(camera.dualCameraModeMenuOptions) { mode in
          if mode == camera.dualCameraModeMenuOptions.last {
            Divider()
          }
          Label {
            Text(mode.label)
          } icon: {
            mode.icon
          }
          .tag(mode.tag)
        }
      }
    } label: {
      FeatureLabelView(
        text: "Dual Camera",
        image: camera.cameraMode.layoutMode?.image ?? Image("custom.camera.dual", bundle: .module),
        isSelected: camera.cameraMode.isMultiCamera,
        hasLabel: hasTransientLabel
      )
    }
  }

  @ViewBuilder func reactionsButton() -> some View {
    Button {
      camera.pickReactionVideo()
    } label: {
      FeatureLabelView(
        text: "React",
        image: Image(systemName: "arrow.2.squarepath"),
        isSelected: camera.cameraMode.isMultiCamera,
        hasLabel: hasTransientLabel
      )
    }
  }
}

struct FeaturesMenu_Previews: PreviewProvider {
  static var previews: some View {
    let engineSettings = EngineSettings(license: "")
    Camera(engineSettings) { _ in }
  }
}
