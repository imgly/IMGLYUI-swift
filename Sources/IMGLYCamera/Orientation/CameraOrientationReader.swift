import Combine
import CoreMotion
import SwiftUI
import UIKit

/// Reads physical orientation independently of rotation lock, and the camera's own window orientation.
struct CameraOrientationReader: UIViewRepresentable {
  var onChange: (UIDeviceOrientation, UIInterfaceOrientation) -> Void

  func makeUIView(context _: Context) -> OrientationView {
    let view = OrientationView()
    view.onChange = onChange
    return view
  }

  func updateUIView(_ view: OrientationView, context _: Context) {
    view.onChange = onChange
  }

  static func dismantleUIView(_ view: OrientationView, coordinator _: ()) {
    view.stop()
  }

  final class OrientationView: UIView {
    var onChange: ((UIDeviceOrientation, UIInterfaceOrientation) -> Void)?
    private var observation: AnyCancellable?
    private var activationObservation: AnyCancellable?
    private let motionManager = CMMotionManager()
    private let motionQueue: OperationQueue = {
      let queue = OperationQueue()
      queue.name = "ly.img.camera.orientation"
      queue.maxConcurrentOperationCount = 1
      return queue
    }()

    private var motionOrientation: CameraOrientation?

    override func didMoveToWindow() {
      super.didMoveToWindow()
      guard window != nil else { stop(); return }
      if observation == nil {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        observation = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
          .sink { [weak self] _ in self?.updateOrientation() }
        activationObservation = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
          .merge(with: NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification))
          .sink { [weak self] notification in
            if notification.name == UIApplication.didBecomeActiveNotification {
              self?.startMotionUpdates()
            } else {
              self?.motionManager.stopDeviceMotionUpdates()
            }
          }
      }
      if UIApplication.shared.applicationState == .active {
        startMotionUpdates()
      }
      updateOrientation()
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      updateOrientation()
    }

    private func updateOrientation() {
      // Avoid publishing during SwiftUI's layout pass.
      DispatchQueue.main.async { [weak self] in
        guard let self, let scene = window?.windowScene else { return }
        onChange?(motionOrientation?.deviceOrientation ?? UIDevice.current.orientation, scene.interfaceOrientation)
      }
    }

    private func startMotionUpdates() {
      guard window != nil, motionManager.isDeviceMotionAvailable, !motionManager.isDeviceMotionActive else { return }
      motionManager.deviceMotionUpdateInterval = 0.1
      motionManager.startDeviceMotionUpdates(to: motionQueue, withHandler: motionUpdateHandler())
    }

    // Core Motion's legacy callback type does not declare Sendable. Specify it here to
    // prevent the closure from inheriting UIView's main-actor isolation on the sensor queue.
    func motionUpdateHandler() -> @Sendable (CMDeviceMotion?, Error?) -> Void {
      { [weak self] motion, _ in
        guard let gravity = motion?.gravity,
              let orientation = CameraOrientation(gravityX: gravity.x, gravityY: gravity.y, gravityZ: gravity.z)
        else { return }
        Task { @MainActor [weak self] in
          guard let self, motionManager.isDeviceMotionActive, motionOrientation != orientation else { return }
          motionOrientation = orientation
          updateOrientation()
        }
      }
    }

    func stop() {
      motionManager.stopDeviceMotionUpdates()
      activationObservation = nil
      guard observation != nil else { return }
      observation = nil
      UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
  }
}
