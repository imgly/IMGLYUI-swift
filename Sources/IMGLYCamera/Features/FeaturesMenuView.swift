import IMGLYCoreUI
import SwiftUI

struct FeaturesMenuView: View {
  @Environment(\.layoutDirection) private var layoutDirection

  @EnvironmentObject var camera: CameraModel

  @State private var isMinimized = false
  @State private var allowsMinimizing = false
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

        if !isMinimized || camera.dualCameraMode != .disabled {
          // Minimizable features go here
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

      if allowsMinimizing {
        minimizeButton()
      }
    }
    .animation(.easeInOut, value: isMinimized)
    .padding(.leading, 12)
    .onAppear {
      showTransientLabels()
    }
  }

  private func showTransientLabels() {
    hasTransientLabel = true
    transientLabelTimer?.invalidate()
    transientLabelTimer = Timer.scheduledTimer(withTimeInterval: labelDisappearInterval, repeats: false, block: { _ in
      hasTransientLabel = false
    })
  }
}

// MARK: -

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
      Picker("Dual Camera", selection: $camera.dualCameraMode) {
        ForEach(DualCameraMode.allCases, id: \.rawValue) { mode in
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
      }
    } label: {
      FeatureLabelView(
        text: "Dual Camera",
        image: camera.dualCameraMode == .disabled
          ? Image("custom.camera.dual", bundle: .module)
          : camera.dualCameraMode.image,
        isSelected: camera.dualCameraMode != .disabled,
        hasLabel: hasTransientLabel
      )
    }
  }

  @ViewBuilder func minimizeButton() -> some View {
    Button {
      showTransientLabels()
      isMinimized.toggle()
    } label: {
      FeatureCloseLabelView(isMinimized: isMinimized)
    }
  }
}

struct FeaturesMenu_Previews: PreviewProvider {
  static var previews: some View {
    let engineSettings = EngineSettings(license: "")
    Camera(engineSettings) { _ in }
  }
}
