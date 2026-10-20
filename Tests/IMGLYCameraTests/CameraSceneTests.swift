import CoreMedia
@testable import IMGLYCamera
import IMGLYEngine
import XCTest

final class CameraSceneTests: XCTestCase {
  @MainActor
  func testMixedOrientationsFillTheFixedPageForPhotosAndVideos() async throws {
    let portrait = CGRect(x: 0, y: 0, width: 1080, height: 1920)
    let landscape = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let url = URL(fileURLWithPath: "/capture.mp4")
    let video = Capture.video(Recording(
      videos: [.init(url: url, rect: landscape)],
      duration: CMTime(value: 2, timescale: 1),
    ))
    let photo = Capture.photo(Photo(
      images: [.init(url: url, rect: portrait)],
      duration: CMTime(value: 3, timescale: 1),
    ))
    let engine = try await Engine()
    for captures in [[video, photo], [photo, video], [video, video]] {
      try await engine.createScene(from: .capture(captures))
      let page = try XCTUnwrap(engine.scene.getCurrentPage())
      XCTAssertEqual(try engine.block.getFrameWidth(page), 1080)
      XCTAssertEqual(try engine.block.getFrameHeight(page), 1920)
      let clips = try engine.block.find(byType: .graphic)
      XCTAssertEqual(clips.count, 2)
      for clip in clips {
        XCTAssertEqual(try engine.block.getFrameWidth(clip), 1080)
        XCTAssertEqual(try engine.block.getFrameHeight(clip), 1920)
        XCTAssertEqual(try engine.block.getPositionX(clip), 0)
        XCTAssertEqual(try engine.block.getPositionY(clip), 0)
      }
    }
  }

  func testLandscapeDualFeedsFitTogetherInsidePortraitPage() {
    let canvas = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let page = CGSize(width: 1080, height: 1920)
    let first = fittedCameraCaptureFrame(CGRect(x: 0, y: 0, width: 960, height: 1080),
                                         canvas: canvas, pageSize: page)
    let second = fittedCameraCaptureFrame(CGRect(x: 960, y: 0, width: 960, height: 1080),
                                          canvas: canvas, pageSize: page)
    XCTAssertEqual(first, CGRect(x: 0, y: 656.25, width: 540, height: 607.5))
    XCTAssertEqual(second, CGRect(x: 540, y: 656.25, width: 540, height: 607.5))
    let overlap = first.intersection(second)
    XCTAssertTrue(overlap.isEmpty)
    XCTAssertTrue(CGRect(origin: .zero, size: page).contains(first.union(second)))
  }
}
