@testable import IMGLYCamera
import SwiftUI
import XCTest

final class CameraRotationTests: XCTestCase {
  func testRelocationKeepsTheOldPositionAndAngleUntilHidden() {
    let initial = CameraRotation()
    let target = CameraRotation(orientation: .landscapeLeft, angle: 90)
    let transition = CameraPositionTransition(position: Alignment.topLeading, rotation: initial)
    XCTAssertTrue(transition.needsRepositioning(to: .topTrailing, rotation: target))
    XCTAssertEqual(transition.position, .topLeading)
    XCTAssertEqual(transition.displayedRotation(at: .topTrailing, rotation: target), initial)
  }

  func testStationaryControlRotatesWithoutFading() {
    for orientation in CameraOrientation.allCases {
      let target = CameraRotation(orientation: orientation, angle: Double(orientation.rawValue))
      let transition = CameraPositionTransition(position: Alignment.center, rotation: CameraRotation())
      XCTAssertFalse(transition.needsRepositioning(to: .center, rotation: target))
      XCTAssertEqual(transition.displayedRotation(at: .center, rotation: target), target)
    }
  }

  func testInterruptedFadeInHidesBeforeChangingAngleAgain() {
    let displayed = CameraRotation(orientation: .landscapeLeft, angle: 90)
    let target = CameraRotation(orientation: .landscapeRight, angle: 270)
    let transition = CameraPositionTransition(position: Alignment.top, rotation: displayed, isMoving: true)
    XCTAssertTrue(transition.needsRepositioning(to: .top, rotation: target))
    XCTAssertEqual(transition.displayedRotation(at: .top, rotation: target), displayed)
  }

  func testReversingFadeOutAtTheOriginalPositionOnlyRestoresOpacity() {
    let initial = CameraRotation()
    let transition = CameraPositionTransition(position: Alignment.topLeading, rotation: initial, isMoving: true)
    XCTAssertFalse(transition.needsRepositioning(to: .topLeading, rotation: initial))
    XCTAssertEqual(transition.displayedRotation(at: .topLeading, rotation: initial), initial)
  }

  @MainActor
  func testTimerStaysCenteredWhenLayoutControlsArePresent() throws {
    for direction in [LayoutDirection.leftToRight, .rightToLeft] {
      for orientation in CameraOrientation.allCases {
        for showsLayoutControl in [false, true] {
          let content = CameraFeaturesLayout(layoutDirection: direction) {
            Color.red.frame(width: 40, height: 40)
            if showsLayoutControl {
              Color.clear.frame(width: 120, height: 56)
            }
          }
          .cameraRotated()
          .frame(width: 300, height: 500, alignment: orientation.featuresAlignment)
          .environment(\.cameraRotation,
                       CameraRotation(orientation: orientation, angle: Double(orientation.rawValue)))
          .environment(\.layoutDirection, direction)
          let renderer = ImageRenderer(content: content)
          let bounds = try opaqueBounds(XCTUnwrap(renderer.cgImage))
          if orientation.isLandscape {
            XCTAssertEqual(bounds.midX, 150, accuracy: 1)
          } else {
            XCTAssertEqual(bounds.midY, 250, accuracy: 1)
          }
        }
      }
    }
  }

  @MainActor
  private final class RotationState: ObservableObject {
    @Published var value = CameraRotation()

    func rotate(_ orientation: CameraOrientation) {
      value = CameraRotation(orientation: orientation, angle: orientation.rotation(from: value.angle))
    }
  }

  private struct PositionedContent: View {
    @ObservedObject var state: RotationState

    var body: some View {
      CameraPositionedView(alignment: state.value.orientation.closeAlignment) {
        Color.red.frame(width: 40, height: 20)
      }
      .environment(\.cameraRotation, state.value)
      .frame(width: 300, height: 500)
    }
  }

  @MainActor
  func testReversingAnUnfinishedMoveRestoresTheControl() async throws {
    let state = RotationState()
    let controller = UIHostingController(rootView: PositionedContent(state: state))
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
    window.rootViewController = controller
    window.isHidden = false
    controller.view.backgroundColor = .clear
    defer { window.isHidden = true }
    try await Task.sleep(for: .milliseconds(100))
    let initial = try opaqueBounds(snapshot(controller.view))
    XCTAssertFalse(initial.isEmpty)
    state.rotate(.landscapeLeft)
    try await Task.sleep(for: .milliseconds(100))
    state.rotate(.portrait)
    try await Task.sleep(for: .milliseconds(800))
    let restored = try opaqueBounds(snapshot(controller.view))
    XCTAssertEqual(restored, initial)
  }

  @MainActor
  func testCapturedPhotoFitsWithoutCroppingInEveryOrientation() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
    defer { try? FileManager.default.removeItem(at: url) }
    let source = UIGraphicsImageRenderer(size: CGSize(width: 160, height: 90)).image { context in
      UIColor.red.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 160, height: 90))
    }
    try XCTUnwrap(source.pngData()).write(to: url)
    let photo = Photo(images: [.init(url: url, rect: CGRect(x: 0, y: 0, width: 1920, height: 1080))], duration: .zero)
    for orientation in CameraOrientation.allCases {
      let content = PhotoPreviewCanvas(photo: photo)
        .environment(\.cameraRotation, CameraRotation(orientation: orientation, angle: Double(orientation.rawValue)))
        .frame(width: 300, height: 500)
        .ignoresSafeArea()
      let controller = UIHostingController(rootView: content)
      let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
      window.rootViewController = controller
      window.isHidden = false
      try await Task.sleep(for: .milliseconds(200))
      let image = try snapshot(controller.view)
      window.isHidden = true
      let bounds = try opaqueBounds(image)
      XCTAssertEqual(bounds.width, orientation.isLandscape ? 281.25 : 300, accuracy: 2)
      XCTAssertEqual(bounds.height, orientation.isLandscape ? 500 : 168.75, accuracy: 2)
    }
  }

  @MainActor
  func testDialogRendersInEveryOrientation() throws {
    for orientation in CameraOrientation.allCases {
      let dialog = CameraDialog(state: .constant(.deleteAll {}))
        .environment(\.cameraRotation, CameraRotation(orientation: orientation, angle: Double(orientation.rawValue)))
        .environment(\.colorScheme, .dark)
        .frame(width: 390, height: 650)
      let renderer = ImageRenderer(content: dialog)
      let image = try XCTUnwrap(renderer.uiImage)
      let attachment = XCTAttachment(image: image)
      attachment.name = "dialog-\(orientation.rawValue)"
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }

  @MainActor
  private func snapshot(_ view: UIView) throws -> CGImage {
    view.layoutIfNeeded()
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return try XCTUnwrap(UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { context in
      view.layer.render(in: context.cgContext)
    }.cgImage)
  }

  @MainActor
  func testSharedRotationKeepsContentCenteredAndFitsItsAspectRatio() throws {
    for orientation in CameraOrientation.allCases {
      let view = Color.red
        .aspectRatio(16 / 9, contentMode: .fit)
        .cameraRotated()
        .environment(\.cameraRotation, CameraRotation(orientation: orientation, angle: Double(orientation.rawValue)))
        .frame(width: 300, height: 500)
      let renderer = ImageRenderer(content: view)
      let image = try XCTUnwrap(renderer.cgImage)
      let bounds = try opaqueBounds(image)
      XCTAssertEqual(bounds.midX, 150, accuracy: 1)
      XCTAssertEqual(bounds.midY, 250, accuracy: 1)
      XCTAssertEqual(bounds.width, orientation.isLandscape ? 281.25 : 300, accuracy: 1)
      XCTAssertEqual(bounds.height, orientation.isLandscape ? 500 : 168.75, accuracy: 1)
    }
  }

  @MainActor
  func testSharedRotationPreservesDialogSizedContentInEveryOrientation() throws {
    for orientation in CameraOrientation.allCases {
      let view = Color.red
        .frame(width: 270, height: 220)
        .cameraRotated()
        .environment(\.cameraRotation, CameraRotation(orientation: orientation, angle: Double(orientation.rawValue)))
        .frame(width: 390, height: 650)
      let renderer = ImageRenderer(content: view)
      let bounds = try opaqueBounds(XCTUnwrap(renderer.cgImage))
      XCTAssertEqual(bounds.midX, 195, accuracy: 1)
      XCTAssertEqual(bounds.midY, 325, accuracy: 1)
      XCTAssertEqual(bounds.width, orientation.isLandscape ? 220 : 270, accuracy: 1)
      XCTAssertEqual(bounds.height, orientation.isLandscape ? 270 : 220, accuracy: 1)
    }
  }

  private func opaqueBounds(_ image: CGImage) throws -> CGRect {
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let context = try XCTUnwrap(CGContext(data: &pixels, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    var bounds = CGRect.null
    for y in 0 ..< height {
      for x in 0 ..< width {
        let index = (y * width + x) * 4
        if pixels[index] > 200, pixels[index + 1] < 100, pixels[index + 2] < 100 {
          bounds = bounds.union(CGRect(x: x, y: y, width: 1, height: 1))
        }
      }
    }
    return bounds
  }
}
