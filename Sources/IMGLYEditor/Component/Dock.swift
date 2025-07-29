import IMGLYEngine
import SwiftUI

@_spi(Internal) public extension EnvironmentValues {
  @Entry var imglyDockItems: Dock.Items?
  @Entry var imglyDockModifications: Dock.Modifications?
  @Entry var imglyDockItemAlignment: Dock.Alignment = { _ in .center }
  @Entry var imglyDockBackgroundColor: Dock.BackgroundColor = { _, colorScheme in colorScheme == .dark
    ? Color(uiColor: .systemBackground)
    : Color(uiColor: .secondarySystemBackground)
  }

  @Entry var imglyDockScrollDisabled: Dock.ScrollDisabled = { _ in false }
}

/// A namespace for the dock component.
public enum Dock {}

public extension Dock {
  /// A type for dock item components.
  protocol Item: EditorComponent where Context == Dock.Context {}
  /// A builder for building arrays of dock ``Item``s.
  typealias Builder = ArrayBuilder<any Item>
  /// A modifier for modifying arrays of dock ``Item``s.
  typealias Modifier = ArrayModifier<any Item, None>

  /// The context of dock components.
  struct Context: EditorContext {
    /// The engine of the current editor.
    public let engine: Engine
    public let eventHandler: EditorEventHandler
    /// The asset library configured with the ``IMGLY/assetLibrary(_:)`` view modifier.
    public let assetLibrary: any AssetLibrary
  }

  /// A closure to build an array of dock ``Item``s.
  typealias Items = Context.SendableTo<[any Item]>
  /// A closure to modify an array of dock ``Item``s.
  typealias Modifications = @Sendable @MainActor (_ context: Context, _ items: Modifier) throws -> Void
  /// A button dock ``Item`` component.
  typealias Button = EditorComponents.Button
  /// A custom dock ``Item`` component.
  typealias Custom = EditorComponents.Custom
}

@_spi(Internal) public extension Dock {
  typealias Alignment = Context.SendableTo<SwiftUI.Alignment>
  typealias ScrollDisabled = Context.SendableTo<Bool>
  typealias BackgroundColor = @Sendable @MainActor (_ context: Context, _ colorScheme: ColorScheme) throws -> SwiftUI
    .Color
}

extension Dock.Button: Dock.Item where Context == Dock.Context {}
extension Dock.Custom: Dock.Item where Context == Dock.Context {}
