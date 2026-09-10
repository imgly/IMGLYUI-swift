import Photos

/// Represents a `PHFetchResult` that can be used as a `RandomAccessCollection` in a SwiftUI view such as `List`,
/// `ForEach`, etc...
@_spi(Internal) public struct MediaResults<Result>: RandomAccessCollection where Result: PHObject {
  /// Represents the underlying results
  @_spi(Internal) public private(set) var result: PHFetchResult<Result>

  /// Instantiates a new instance with the specified result
  @_spi(Internal) public init(_ result: PHFetchResult<Result>) {
    self.result = result
  }

  @_spi(Internal) public var startIndex: Int { 0 }
  @_spi(Internal) public var endIndex: Int { result.count }
  @_spi(Internal) public subscript(position: Int) -> Result { result.object(at: position) }
}

/// An observer used to observe changes on a `PHFetchResult`
final class ResultsObserver<Result>: NSObject, ObservableObject,
  PHPhotoLibraryChangeObserver where Result: PHObject {
  @Published
  var result: PHFetchResult<Result>

  deinit {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
  }

  init(result: PHFetchResult<Result>) {
    self.result = result
    super.init()
    PHPhotoLibrary.shared().register(self)
  }

  func photoLibraryDidChange(_ changeInstance: PHChange) {
    result = changeInstance.changeDetails(for: result)?.fetchResultAfterChanges ?? result
  }
}
