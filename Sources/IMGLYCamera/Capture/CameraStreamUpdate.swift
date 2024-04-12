import AVFoundation

/// The continous camera stream provides frames for either camera and finished recordings.
enum CaptureStreamUpdate: @unchecked Sendable {
  case output1Frame(CVImageBuffer)
  case output2Frame(CVImageBuffer)
  case recording(Recording)
}
