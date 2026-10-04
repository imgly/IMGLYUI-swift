import AVFoundation
@testable import IMGLYCamera
import IMGLYCore
import XCTest

final class CameraOrientationTests: XCTestCase {
  @MainActor
  func testMotionCallbackCanRunOnTheSensorQueue() async {
    let view = CameraOrientationReader.OrientationView()
    let handler = view.motionUpdateHandler()
    let queue = OperationQueue()
    await withCheckedContinuation { continuation in
      queue.addOperation {
        XCTAssertFalse(Thread.isMainThread)
        handler(nil, nil)
        continuation.resume()
      }
    }
  }

  @MainActor
  func testGravityRotatesCameraWhileInterfaceRemainsLockedInPortrait() throws {
    let camera = CameraModel(EngineSettings(license: ""), onDismiss: .modern { _ in })
    let samples: [(gravity: SIMD2<Double>, orientation: CameraOrientation)] = [
      (.init(0, -1), .portrait), (.init(-1, 0), .landscapeLeft),
      (.init(0, 1), .upsideDown), (.init(1, 0), .landscapeRight),
    ]
    for sample in samples {
      let orientation = try XCTUnwrap(CameraOrientation(gravityX: sample.gravity.x, gravityY: sample.gravity.y,
                                                        gravityZ: 0))
      camera.updateOrientation(device: orientation.deviceOrientation, interface: .portrait)
      XCTAssertEqual(camera.rotation.orientation, sample.orientation)
      XCTAssertEqual(camera.interfaceOrientation, .portrait)
      XCTAssertEqual(CameraOrientation(orientation.deviceOrientation), orientation)
    }
  }

  func testGravityIgnoresFlatAndAmbiguousPoses() {
    XCTAssertNil(CameraOrientation(gravityX: 0, gravityY: 0, gravityZ: -1))
    XCTAssertNil(CameraOrientation(gravityX: 0, gravityY: 0, gravityZ: 1))
    XCTAssertNil(CameraOrientation(gravityX: -0.7, gravityY: -0.7, gravityZ: 0))
    XCTAssertNil(CameraOrientation(gravityX: -0.72, gravityY: -0.69, gravityZ: 0))
    XCTAssertNil(CameraOrientation(gravityX: .nan, gravityY: -1, gravityZ: 0))
  }

  func testGravityChangesOrientationOnlyBeyondTheDiagonalDeadBand() {
    XCTAssertEqual(CameraOrientation(gravityX: -0.5, gravityY: -0.86, gravityZ: 0), .portrait)
    XCTAssertNil(CameraOrientation(gravityX: -0.7, gravityY: -0.7, gravityZ: 0))
    XCTAssertEqual(CameraOrientation(gravityX: -0.86, gravityY: -0.5, gravityZ: 0), .landscapeLeft)
  }

  @MainActor
  func testHostInterfaceRotationDoesNotChangeDeviceOrientation() {
    let camera = CameraModel(EngineSettings(license: ""), onDismiss: .modern { _ in })
    camera.updateOrientation(device: .landscapeLeft, interface: .portrait)
    let rotation = camera.rotation
    for interface in [UIInterfaceOrientation.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown] {
      camera.updateOrientation(device: .landscapeLeft, interface: interface)
      XCTAssertEqual(camera.rotation, rotation)
      XCTAssertEqual(camera.interfaceOrientation, CameraOrientation(interface))
      // A flat device must retain the last physical orientation even if the host rotates.
      camera.updateOrientation(device: .faceUp, interface: interface)
      XCTAssertEqual(camera.rotation, rotation)
    }
  }

  @MainActor
  func testMixedModeTimecodeFollowsTheActiveCaptureMode() {
    let camera = CameraModel(EngineSettings(license: ""), config: .init(captureType: .mixed),
                             onDismiss: .modern { _ in })
    XCTAssertFalse(camera.isVideoModeActive)
    camera.activeMixedSubMode = .video
    XCTAssertTrue(camera.isVideoModeActive)
    camera.activeMixedSubMode = .photo
    XCTAssertFalse(camera.isVideoModeActive)
  }

  func testAllReactionClipsAndSourceRetainTheFirstTakesGeometry() throws {
    let url = URL(fileURLWithPath: "/reaction.mp4")
    for layout in CameraLayoutMode.allCases {
      for swapped in [false, true] {
        let mode = CameraMode.reaction(layout, video: url, positionsSwapped: swapped)
        for firstOrientation in CameraOrientation.allCases {
          var state = CaptureOrientationState()
          state.update(firstOrientation)
          state.lock()
          let sourceRect = firstOrientation.captureRect(mode.rect1)
          let recordingRect = firstOrientation.captureRect(mode.firstRecordingRect)
          for nextOrientation in CameraOrientation.allCases {
            state.update(nextOrientation)
            state.lock()
            let source = try XCTUnwrap(mode.reactionVideo(duration: .zero, orientation: state.orientation))
            XCTAssertEqual(source.videos.first?.rect, sourceRect)
            XCTAssertEqual(state.orientation.captureRect(mode.firstRecordingRect), recordingRect)
          }
          state.unlock()
          XCTAssertEqual(state.orientation, state.preview)
        }
      }
    }
  }

  func testFlatAndUnknownDeviceOrientationsDoNotReplaceTheLastOrientation() {
    XCTAssertNil(CameraOrientation(UIDeviceOrientation.faceUp))
    XCTAssertNil(CameraOrientation(UIDeviceOrientation.faceDown))
    XCTAssertNil(CameraOrientation(UIDeviceOrientation.unknown))
  }

  func testDeviceAndInterfaceLandscapeDirectionsAreOpposite() {
    XCTAssertEqual(CameraOrientation(UIDeviceOrientation.landscapeLeft), .landscapeLeft)
    XCTAssertEqual(CameraOrientation(UIInterfaceOrientation.landscapeRight), .landscapeLeft)
    XCTAssertEqual(CameraOrientation(UIDeviceOrientation.landscapeRight), .landscapeRight)
    XCTAssertEqual(CameraOrientation(UIInterfaceOrientation.landscapeLeft), .landscapeRight)
    XCTAssertEqual(CameraOrientation.landscapeLeft.videoOrientation, .landscapeRight)
    XCTAssertEqual(CameraOrientation.landscapeRight.videoOrientation, .landscapeLeft)
  }

  func testRotationCrossesPortraitAlongTheShortestArc() {
    XCTAssertEqual(CameraOrientation.portrait.rotation(from: 270), 360)
    XCTAssertEqual(CameraOrientation.landscapeRight.rotation(from: 0), -90)
    XCTAssertEqual(CameraOrientation.landscapeLeft.rotation(from: 720), 810)
    XCTAssertEqual(CameraOrientation.portrait.rotation(from: -450), -360)
  }

  func testCaptureCoordinatesRotateCounterclockwiseIntoUprightLandscape() {
    let topHalf = CGRect(x: 0, y: 0, width: 1080, height: 960)
    XCTAssertEqual(CameraOrientation.portrait.captureRect(topHalf), topHalf)
    XCTAssertEqual(CameraOrientation.landscapeLeft.captureRect(topHalf),
                   CGRect(x: 0, y: 0, width: 960, height: 1080))
    XCTAssertEqual(CameraOrientation.upsideDown.captureRect(topHalf),
                   CGRect(x: 0, y: 960, width: 1080, height: 960))
    XCTAssertEqual(CameraOrientation.landscapeRight.captureRect(topHalf),
                   CGRect(x: 960, y: 0, width: 960, height: 1080))
  }

  func testEveryDualLayoutCoversTheUprightCanvasWithoutOverlap() throws {
    for layout in CameraLayoutMode.allCases {
      let mode = CameraMode.dualCamera(layout)
      for orientation in CameraOrientation.allCases {
        let first = orientation.captureRect(mode.rect1)
        let second = orientation.captureRect(try XCTUnwrap(mode.rect2))
        let expected = orientation.isLandscape
          ? CGRect(x: 0, y: 0, width: 1920, height: 1080)
          : CGRect(x: 0, y: 0, width: 1080, height: 1920)
        XCTAssertEqual(first.union(second), expected)
        let overlap = first.intersection(second)
        XCTAssertTrue(overlap.isEmpty)
      }
    }
  }

  func testReactionOutputRetainsSwappedPositionsInEveryOrientation() throws {
    let url = URL(fileURLWithPath: "/reaction.mp4")
    for layout in CameraLayoutMode.allCases {
      for swapped in [false, true] {
        let mode = CameraMode.reaction(layout, video: url, positionsSwapped: swapped)
        for orientation in CameraOrientation.allCases {
          let video = try XCTUnwrap(mode.reactionVideo(duration: .zero, orientation: orientation)?.videos.first)
          let recordingRect = orientation.captureRect(mode.firstRecordingRect)
          XCTAssertEqual(video.rect, orientation.captureRect(mode.rect1))
          let overlap = video.rect.intersection(recordingRect)
          XCTAssertTrue(overlap.isEmpty)
          XCTAssertEqual(video.rect.union(recordingRect).size,
                         orientation.isLandscape ? CGSize(width: 1920, height: 1080) : CGSize(
                           width: 1080,
                           height: 1920,
                         ))
        }
      }
    }
  }

  func testReactionOrientationRemainsLockedAcrossClipsUntilAllAreDeleted() {
    var state = CaptureOrientationState()
    state.update(.landscapeLeft)
    state.lock()
    state.update(.upsideDown)
    state.lock()
    XCTAssertEqual(state.preview, .upsideDown)
    XCTAssertEqual(state.orientation, .landscapeLeft)
    state.unlock()
    XCTAssertEqual(state.orientation, .upsideDown)
    state.lock()
    state.update(.portrait)
    XCTAssertEqual(state.orientation, .upsideDown)
  }
}
