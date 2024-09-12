import CoreGraphics
import IMGLYEngine

@_spi(Internal) public extension BlockAPI {
  /// Update the block's size and position.
  /// Required scope: "layer/resize".
  /// - Parameters:
  ///   - id: The block to update.
  ///   - value: The new frame of the
  func setFrame(_ id: DesignBlockID, value: CGRect) throws {
    try setPosition(id, value: value.origin)
    try setSize(id, value: value.size)
  }

  /// Update a block's position.
  /// The position refers to the block's local space, relative to its parent with the origin at the top left.
  /// Required scope: "layer/move"
  /// - Parameters:
  ///   - id: The block to update.
  ///   - value: The value of the position.
  func setPosition(_ id: DesignBlockID, value: CGPoint) throws {
    try setPositionX(id, value: Float(value.x))
    try setPositionY(id, value: Float(value.y))
  }

  /// Update a block's size
  /// Required scope: "layer/resize"
  /// - Parameters:
  ///   - id: The block to update.
  ///   - value: The new size of the block.
  func setSize(_ id: DesignBlockID, value: CGSize) throws {
    try setWidth(id, value: Float(value.width))
    try setHeight(id, value: Float(value.height))
  }
}
