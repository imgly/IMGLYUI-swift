import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

/// Defines the behavior when applying a force crop preset.
public enum ForceCropMode: CaseIterable, Sendable {
  /// Applies the preset without opening the crop UI.
  case silent
  /// Applies the preset and always opens the crop UI.
  case always
  /// Only applies the preset if dimensions differ, then opens the crop UI.
  case ifNeeded
}

/// A crop preset candidate for force crop operations.
///
/// When applying force crop with multiple preset candidates, the system automatically selects
/// the best matching preset based on the block's current dimensions.
public struct ForceCropPreset {
  /// The ID of the asset source containing the crop preset.
  let sourceID: String
  /// The ID of the crop preset within the asset source.
  let presetID: String

  /// Creates a new force crop preset candidate.
  /// - Parameters:
  ///   - sourceID: The ID of the asset source containing the crop preset.
  ///   - presetID: The ID of the crop preset within that source.
  public init(sourceID: String, presetID: String) {
    self.sourceID = sourceID
    self.presetID = presetID
  }
}

struct ForceCropState {
  let blockID: DesignBlockID
  let sourceID: String
}

extension Interactor {
  func isForceCropActive(for blockID: DesignBlockID?) -> Bool {
    guard let forceCropState, let blockID else { return false }
    return forceCropState.blockID == blockID
  }

  func applyForceCrop(
    to blockID: DesignBlockID,
    presetCandidates: [ForceCropPreset],
    mode: ForceCropMode,
  ) async throws {
    guard let engine else {
      throw Error(errorDescription: "Engine not available")
    }

    do {
      try validateBlock(blockID, engine: engine)

      var resolvedPresets: [(preset: AssetResult, sourceID: String)] = []

      for candidate in presetCandidates {
        if let cropPreset = try? await fetchAndValidatePreset(
          sourceID: candidate.sourceID,
          presetID: candidate.presetID,
          engine: engine,
        ) {
          resolvedPresets.append((preset: cropPreset, sourceID: candidate.sourceID))
        }
      }

      guard !resolvedPresets.isEmpty else {
        throw Error(errorDescription: "No valid crop presets found")
      }

      let bestMatch = try await findBestMatch(
        from: resolvedPresets,
        engine: engine,
        blockID: blockID,
      )

      let shouldApply = switch mode {
      case .silent, .always: true
      case .ifNeeded: try await isPresetNeeded(engine: engine, cropPreset: bestMatch.preset, blockID: blockID)
      }

      if shouldApply {
        try await applyCropPreset(
          sourceID: bestMatch.sourceID,
          cropPreset: bestMatch.preset,
          to: blockID,
          updateZoom: mode == .silent,
        )

        if mode != .silent {
          try await Task.sleep(for: .milliseconds(100))
          send(.openSheet(type: .crop(id: blockID, assetSourceIDs: [bestMatch.sourceID])))
        }
      }

      forceCropState = ForceCropState(blockID: blockID, sourceID: bestMatch.sourceID)
    } catch {
      forceCropState = nil
      throw error
    }
  }

  private func applyCropPreset(
    sourceID: String,
    cropPreset: AssetResult,
    to blockID: DesignBlockID,
    updateZoom: Bool,
  ) async throws {
    guard let engine else {
      throw Error(errorDescription: "Engine not available")
    }

    do {
      try await engine.asset.applyToBlock(sourceID: sourceID, assetResult: cropPreset, block: blockID)

      guard let scene = try engine.scene.get() else { return }

      try applyTransformPresetSceneProperties(engine: engine, scene: scene, asset: cropPreset, blockID: blockID)

      if updateZoom {
        self.updateZoom(
          for: .pageSizeChanged,
          with: (zoomModel.defaultInsets, zoomModel.canvasHeight, zoomModel.padding),
        )
        isResizingPages = true
      }
    } catch {
      handleError(error)
      throw error
    }
  }

  private func validateBlock(_ blockID: DesignBlockID, engine: Engine) throws {
    guard engine.block.isValid(blockID) else {
      throw Error(errorDescription: "Invalid block ID: \(blockID)")
    }

    guard try engine.block.supportsCrop(blockID) else {
      throw Error(errorDescription: "Block does not support cropping: \(blockID)")
    }
  }

  private func fetchAndValidatePreset(
    sourceID: String,
    presetID: String,
    engine: Engine,
  ) async throws -> AssetResult {
    guard engine.asset.findAllSources().contains(sourceID) else {
      throw Error(errorDescription: "Asset source not found: \(sourceID)")
    }

    guard let cropPreset = try await engine.asset.fetchAsset(sourceID: sourceID, assetID: presetID) else {
      throw Error(errorDescription: "Crop preset not found: \(presetID) in source: \(sourceID)")
    }

    guard cropPreset.payload?.transformPreset != nil else {
      throw Error(errorDescription: "Asset does not contain a valid transform preset")
    }

    return cropPreset
  }

  private func findBestMatch(
    from resolvedPresets: [(preset: AssetResult, sourceID: String)],
    engine: Engine,
    blockID: DesignBlockID,
  ) async throws -> (preset: AssetResult, sourceID: String) {
    if resolvedPresets.count == 1 {
      return resolvedPresets[0]
    }

    var bestMatch = resolvedPresets[0]
    var bestScore = try await calculateFitScore(
      engine: engine,
      blockID: blockID,
      preset: bestMatch.preset,
    )

    for candidate in resolvedPresets.dropFirst() {
      let score = try await calculateFitScore(
        engine: engine,
        blockID: blockID,
        preset: candidate.preset,
      )

      if score < bestScore {
        bestScore = score
        bestMatch = candidate
      }
    }

    return bestMatch
  }

  private func calculateFitScore(
    engine: Engine,
    blockID: DesignBlockID,
    preset: AssetResult,
  ) async throws -> Float {
    guard let transformPreset = preset.payload?.transformPreset else {
      return Float.greatestFiniteMagnitude
    }

    let frameWidth = try engine.block.getFrameWidth(blockID)
    let frameHeight = try engine.block.getFrameHeight(blockID)

    switch transformPreset {
    case .freeAspectRatio:
      return Float.greatestFiniteMagnitude

    case let .fixedAspectRatio(width, height):
      let frameAspectRatio = frameHeight / frameWidth
      let presetAspectRatio = height / width
      return abs(frameAspectRatio - presetAspectRatio)

    case let .fixedSize(width, height, designUnit):
      let harmonized = try await harmonizeDimensions(
        engine: engine,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        designUnit: designUnit,
      )
      return abs(harmonized.width - width) + abs(harmonized.height - height)

    default:
      return Float.greatestFiniteMagnitude
    }
  }

  private func harmonizeDimensions(
    engine: Engine,
    frameWidth: Float,
    frameHeight: Float,
    designUnit: DesignUnit,
  ) async throws -> (width: Float, height: Float) {
    let sceneDesignUnit = try engine.scene.getDesignUnit()

    guard designUnit != sceneDesignUnit else {
      return (width: frameWidth, height: frameHeight)
    }

    guard let scene = try engine.scene.get() else {
      return (width: frameWidth, height: frameHeight)
    }

    let dpi = (try? engine.block.getFloat(scene, property: "scene/dpi")) ?? 72.0
    let pixelScale = (try? engine.block.getFloat(scene, property: "scene/pixelScaleFactor")) ?? 1.0

    let harmonizedWidth = DesignUnit.convert(
      frameWidth,
      from: sceneDesignUnit,
      to: designUnit,
      dpi: dpi,
      pixelScale: pixelScale,
    )

    let harmonizedHeight = DesignUnit.convert(
      frameHeight,
      from: sceneDesignUnit,
      to: designUnit,
      dpi: dpi,
      pixelScale: pixelScale,
    )

    return (width: harmonizedWidth, height: harmonizedHeight)
  }

  private func isPresetNeeded(
    engine: Engine,
    cropPreset: AssetResult,
    blockID: DesignBlockID,
  ) async throws -> Bool {
    let frameDimensions = (
      width: try engine.block.getFrameWidth(blockID),
      height: try engine.block.getFrameHeight(blockID),
    )

    guard let transformPreset = cropPreset.payload?.transformPreset else {
      throw Error(errorDescription: "The selected preset does not have a valid transform preset.")
    }

    switch transformPreset {
    case .freeAspectRatio:
      return true
    case let .fixedAspectRatio(width, height):
      return isFixedAspectRatioNeeded(frameDimensions: frameDimensions, width: width, height: height)
    case let .fixedSize(width, height, designUnit):
      return try await isFixedSizeNeeded(
        engine: engine,
        frameDimensions: frameDimensions,
        width: width,
        height: height,
        designUnit: designUnit,
      )
    default:
      throw Error(errorDescription: "The selected preset does not have a valid transform preset.")
    }
  }

  private func isFixedAspectRatioNeeded(
    frameDimensions: (width: Float, height: Float),
    width: Float,
    height: Float,
  ) -> Bool {
    let frameRatio = (frameDimensions.height / frameDimensions.width).rounded(toDecimalPlaces: 4)
    let presetRatio = (height / width).rounded(toDecimalPlaces: 4)
    return frameRatio != presetRatio
  }

  private func isFixedSizeNeeded(
    engine: Engine,
    frameDimensions: (width: Float, height: Float),
    width: Float,
    height: Float,
    designUnit: DesignUnit,
  ) async throws -> Bool {
    let sceneDesignUnit = try engine.scene.getDesignUnit()

    let harmonizedFrameDimensions: (width: Float, height: Float)

    if designUnit != sceneDesignUnit {
      guard let scene = try engine.scene.get() else {
        return true
      }
      let dpi = (try? engine.block.getFloat(scene, property: "scene/dpi")) ?? 72.0
      let pixelScale = (try? engine.block.getFloat(scene, property: "scene/pixelScaleFactor")) ?? 1.0

      harmonizedFrameDimensions = (
        width: DesignUnit.convert(
          frameDimensions.width,
          from: sceneDesignUnit,
          to: designUnit,
          dpi: dpi,
          pixelScale: pixelScale,
        ),
        height: DesignUnit.convert(
          frameDimensions.height,
          from: sceneDesignUnit,
          to: designUnit,
          dpi: dpi,
          pixelScale: pixelScale,
        ),
      )
    } else {
      harmonizedFrameDimensions = frameDimensions
    }

    if !almostEqual(harmonizedFrameDimensions.width, width) || !almostEqual(harmonizedFrameDimensions.height, height) {
      try engine.scene.setDesignUnit(designUnit)
      return true
    }

    return false
  }

  private func almostEqual(_ a: Float, _ b: Float, epsilon: Float = Float.ulpOfOne) -> Bool {
    abs(a - b) < epsilon
  }
}

private extension Float {
  func rounded(toDecimalPlaces places: Int) -> Float {
    let multiplier = pow(10.0, Float(places))
    return (self * multiplier).rounded() / multiplier
  }
}
