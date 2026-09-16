@_spi(Internal) import IMGLYCore
import IMGLYEngine

/// Transition assets use the same payload schema as animations. Keeping this adapter separate
/// leaves transition-specific localization and metadata free to diverge without copying the
/// generic property conversion code.
enum TransitionPropertyDefinitions {
  static func properties(
    from assetProperties: [AssetProperty],
    sourceID: String,
    assetResult: AssetResult,
    transitionBlockID: Interactor.BlockID,
  ) -> [EffectProperty] {
    AnimationPropertyDefinitions.properties(
      from: assetProperties,
      sourceID: sourceID,
      assetResult: assetResult,
      animationBlockID: transitionBlockID,
    )
  }
}
