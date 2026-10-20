@testable import IMGLYCamera
import SwiftUI
import XCTest

final class CameraScreenLayoutTests: XCTestCase {
  @MainActor
  private final class Frames {
    var preview = CGRect.zero
    var controls = CGRect.zero
  }

  @MainActor
  func testLandscapePreviewReachesHomeIndicatorEdgeAndControlsStayInset() async throws {
    for orientation in [CameraOrientation.landscapeLeft, .landscapeRight] {
      for direction in [LayoutDirection.leftToRight, .rightToLeft] {
        let frames = Frames()
        let content = CameraScreenLayout(orientation: orientation) { insets in
          ZStack {
            Color.red.background {
              GeometryReader { geometry in
                Color.clear.onAppear { frames.preview = geometry.frame(in: .global) }
              }
            }
            Color.green.background {
              GeometryReader { geometry in
                Color.clear.onAppear { frames.controls = geometry.frame(in: .global) }
              }
            }
            .padding(insets)
          }
        }
        .environment(\.layoutDirection, direction)
        let controller = UIHostingController(rootView: content)
        controller.additionalSafeAreaInsets.bottom = 21
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 852, height: 393))
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        controller.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(100))
        let safeFrame = controller.view.safeAreaLayoutGuide.layoutFrame
        XCTAssertGreaterThan(controller.view.safeAreaInsets.bottom, 0)
        XCTAssertEqual(frames.preview.maxY, controller.view.bounds.maxY, accuracy: 1)
        XCTAssertEqual(frames.controls.maxY, safeFrame.maxY, accuracy: 1, "\(orientation), \(direction)")
        XCTAssertEqual(frames.controls.minY, safeFrame.minY, accuracy: 1, "\(orientation), \(direction)")
        XCTAssertEqual(frames.preview.minX, safeFrame.minX, accuracy: 1)
        XCTAssertEqual(frames.preview.maxX, safeFrame.maxX, accuracy: 1)
      }
    }
  }

  @MainActor
  func testPortraitLayoutKeepsTheExistingSafeArea() async throws {
    let frames = Frames()
    let content = CameraScreenLayout(orientation: .portrait) { _ in
      Color.red.background {
        GeometryReader { geometry in
          Color.clear.onAppear { frames.preview = geometry.frame(in: .global) }
        }
      }
    }
    let controller = UIHostingController(rootView: content)
    controller.additionalSafeAreaInsets.bottom = 21
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    window.rootViewController = controller
    window.isHidden = false
    defer { window.isHidden = true }
    controller.view.layoutIfNeeded()
    try await Task.sleep(for: .milliseconds(100))
    XCTAssertEqual(frames.preview, controller.view.safeAreaLayoutGuide.layoutFrame)
  }
}
