@_spi(Internal) public typealias Scope = RawRepresentableKey<ScopeKey>

@_spi(Internal) public enum ScopeKey: String {
  case appearanceAdjustments = "appearance/adjustments"
  case appearanceFilter = "appearance/filter"
  case appearanceEffect = "appearance/effect"
  case appearanceBlur = "appearance/blur"
  case appearanceShadow = "appearance/shadow"

  case editorAdd = "editor/add"
  case editorSelect = "editor/select"

  case fillChange = "fill/change"
  case fillChangeType = "fill/changeType"

  case layerCrop = "layer/crop"
  case layerMove = "layer/move"
  case layerResize = "layer/resize"
  case layerRotate = "layer/rotate"
  case layerFlip = "layer/flip"
  case layerOpacity = "layer/opacity"
  case layerBlendMode = "layer/blendMode"
  case layerVisibility = "layer/visibility"
  case layerClipping = "layer/clipping"

  case lifecycleDestroy = "lifecycle/destroy"
  case lifecycleDuplicate = "lifecycle/duplicate"

  case strokeChange = "stroke/change"

  case shapeChange = "shape/change"

  case textEdit = "text/edit"
  case textCharacter = "text/character"
}
