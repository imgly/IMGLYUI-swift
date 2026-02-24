import os.lock
import PhotosUI
@_spi(Internal) import IMGLYCore

extension PHPhotoLibrary: IMGLYCompatible {}

private final class ResumeGuard: @unchecked Sendable {
  private var hasResumed = false
  private let lock = OSAllocatedUnfairLock()

  func tryResume() -> Bool {
    lock.withLock {
      guard !hasResumed else { return false }
      hasResumed = true
      return true
    }
  }
}

@_spi(Internal) public extension IMGLY where Wrapped == PHPhotoLibrary {
  /// Present the limited library picker with a safe async wrapper.
  ///
  /// On iOS 17.0+, uses the native async API. On iOS 16 and earlier, guards
  /// against a bug where the completion handler may be called multiple times,
  /// which would cause a "continuation resumed more than once" fatal error.
  ///
  /// - Parameter controller: The view controller to present the picker from.
  /// - Returns: An array of local identifiers for the newly selected assets.
  @MainActor
  func presentLimitedLibraryPicker(from controller: UIViewController) async -> [String] {
    if #available(iOS 17.0, *) {
      // iOS 17+ has the bug fixed, use native async API
      await wrapped.presentLimitedLibraryPicker(from: controller)
    } else {
      // iOS 16 and earlier: guard against multiple callbacks
      await withCheckedContinuation { (continuation: CheckedContinuation<[String], Never>) in
        let resumeGuard = ResumeGuard()

        wrapped.presentLimitedLibraryPicker(from: controller) { identifiers in
          guard resumeGuard.tryResume() else { return }
          continuation.resume(returning: identifiers)
        }
      }
    }
  }
}
