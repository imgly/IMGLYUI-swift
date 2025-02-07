import IMGLYEngine
import SwiftUI

struct DockKey: EnvironmentKey {
  static let defaultValue: Dock.Items? = nil
}

@_spi(Internal) public extension EnvironmentValues {
  var imglyDock: Dock.Items? {
    get { self[DockKey.self] }
    set { self[DockKey.self] = newValue }
  }
}

@_spi(Unstable) public enum Dock {}

@_spi(Unstable) public extension Dock {
  protocol Item: EditorComponent where Context == Dock.Context {}
  typealias Builder = ArrayBuilder<any Item>

  struct Context: EditorContext {
    @_spi(Unstable) public let engine: Engine
    @_spi(Unstable) public let eventHandler: EditorEventHandler
    @_spi(Unstable) public let assetLibrary: any AssetLibrary
  }

  typealias Items = Context.SendableTo<[any Item]>
  typealias Button = EditorComponents.Button
}

extension Dock.Button: Dock.Item where Context == Dock.Context {}
