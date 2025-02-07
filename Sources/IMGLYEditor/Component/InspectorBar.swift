import IMGLYEngine
import SwiftUI

struct InspectorBarKey: EnvironmentKey {
  static let defaultValue: InspectorBar.Items? = nil
}

@_spi(Internal) public extension EnvironmentValues {
  var imglyInspectorBar: InspectorBar.Items? {
    get { self[InspectorBarKey.self] }
    set { self[InspectorBarKey.self] = newValue }
  }
}

@_spi(Unstable) public enum InspectorBar {}

@_spi(Unstable) public extension InspectorBar {
  protocol Item: EditorComponent where Context == InspectorBar.Context {}
  typealias Builder = ArrayBuilder<any Item>

  struct Context: EditorContext {
    @_spi(Unstable) public let engine: Engine
    @_spi(Unstable) public let eventHandler: EditorEventHandler
    @_spi(Unstable) public let assetLibrary: any AssetLibrary
    @_spi(Unstable) public let selection: Selection
  }

  typealias Items = Context.SendableTo<[any Item]>
  typealias Button = EditorComponents.Button
}

extension InspectorBar.Button: InspectorBar.Item where Context == InspectorBar.Context {}

@_spi(Unstable) public extension InspectorBar.Context {
  struct Selection {
    @_spi(Unstable) public let id: DesignBlockID
    @_spi(Unstable) public let parent: DesignBlockID?
    @_spi(Unstable) public let type: DesignBlockType?
    @_spi(Unstable) public let fillType: FillType?
    @_spi(Unstable) public let kind: String?

    @MainActor
    init(id: DesignBlockID, engine: Engine) throws {
      self.id = id
      parent = try engine.block.getParent(id)
      type = try .init(rawValue: engine.block.getType(id))
      fillType = try engine.block
        .supportsFill(id) ? .init(rawValue: engine.block.getType(engine.block.getFill(id))) : nil
      kind = try engine.block.getKind(id)
    }
  }
}
