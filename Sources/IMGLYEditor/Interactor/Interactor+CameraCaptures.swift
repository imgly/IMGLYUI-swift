import CoreGraphics
import Foundation
import IMGLYCamera
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine

extension Interactor {
  func addCameraCaptures(_ captures: [Capture], addToBackgroundTrack: Bool) {
    if addToBackgroundTrack {
      addCameraCapturesToTimeline(captures)
    } else {
      addCameraCapturesToCurrentPage(captures)
    }
  }

  private func addCameraCapturesToCurrentPage(_ captures: [Capture]) {
    var singleAssets: [(URL, MediaType)] = []
    var dualPhotos: [Photo] = []
    for capture in captures {
      switch capture {
      case let .photo(photo) where photo.images.count > 1:
        dualPhotos.append(photo)
      case let .photo(photo):
        if let url = photo.images.first?.url {
          singleAssets.append((url, .image))
        }
      case let .video(recording):
        for video in recording.videos {
          singleAssets.append((video.url, .movie))
        }
      }
    }
    if !singleAssets.isEmpty {
      addAssetsFromImagePicker(singleAssets)
    }
    if !dualPhotos.isEmpty {
      addDualCameraPhotosToCurrentPage(dualPhotos)
    }
  }

  private func addDualCameraPhotosToCurrentPage(_ photos: [Photo]) {
    Task {
      isAddingCameraRecording = true
      defer { isAddingCameraRecording = false }
      var lastBlockID: DesignBlockID?
      do {
        for photo in photos {
          for image in photo.images {
            let asset = try await uploadImage(to: imageUploadAssetSourceID) { image.url }
            guard let assetURL = asset.url else { continue }
            if let id = try placeDualCameraImageOnPage(fileURL: assetURL, rect: image.rect) {
              lastBlockID = id
            }
          }
        }
      } catch {
        handleError(error)
      }
      if let id = lastBlockID {
        select(id: id)
      }
      addUndoStep()
    }
  }

  @MainActor
  private func placeDualCameraImageOnPage(fileURL: URL, rect: CGRect) throws -> DesignBlockID? {
    guard let engine, let pageID = try engine.scene.getCurrentPage() else { return nil }
    let pageWidth = try engine.block.getFrameWidth(pageID)
    let pageHeight = try engine.block.getFrameHeight(pageID)
    let cameraSize = CameraConfiguration.defaultVideoSize
    let scale = CGFloat(min(pageWidth / Float(cameraSize.width), pageHeight / Float(cameraSize.height)))
    let canvasOrigin = CGPoint(
      x: (CGFloat(pageWidth) - cameraSize.width * scale) / 2,
      y: (CGFloat(pageHeight) - cameraSize.height * scale) / 2,
    )
    let frame = CGRect(
      x: canvasOrigin.x + rect.origin.x * scale,
      y: canvasOrigin.y + rect.origin.y * scale,
      width: rect.width * scale,
      height: rect.height * scale,
    )
    return try placeImageGraphic(at: frame, fillURL: fileURL, parent: pageID, fillMode: .cover)
  }

  @MainActor
  func placeImageGraphic(
    at frame: CGRect,
    fillURL: URL,
    parent: DesignBlockID,
    fillMode: IMGLYEngine.ContentFillMode? = nil,
  ) throws -> DesignBlockID? {
    guard let engine else { return nil }
    let id = try engine.block.create(.graphic)
    try engine.block.setShape(id, shape: engine.block.createShape(.rect))
    try engine.block.appendChild(to: parent, child: id)
    try engine.block.setPositionXMode(id, mode: .absolute)
    try engine.block.setPositionYMode(id, mode: .absolute)
    try engine.block.setWidth(id, value: Float(frame.width))
    try engine.block.setHeight(id, value: Float(frame.height))
    try engine.block.setPositionX(id, value: Float(frame.origin.x))
    try engine.block.setPositionY(id, value: Float(frame.origin.y))
    let fill = try engine.block.createFill(.image)
    try engine.block.set(fill, property: .key(.fillImageImageFileURI), value: fillURL)
    try engine.block.setFill(id, fill: fill)
    if let fillMode {
      try engine.block.setContentFillMode(id, mode: fillMode)
    }
    return id
  }
}
