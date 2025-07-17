import Foundation
@_spi(Internal) import IMGLYCore
import SwiftUI

@_spi(Internal) public struct AlertState: Equatable {
  var id: UUID
  var title: String
  var message: String?
  var buttons: [ButtonState]

  @_spi(Internal) public init(
    title: String,
    message: String? = nil,
    buttons: [ButtonState]
  ) {
    id = UUID()
    self.title = title
    self.message = message
    self.buttons = buttons
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

@_spi(Internal) public struct ButtonState: Identifiable, Equatable {
  public var id: UUID
  var title: String
  var role: ButtonRole?
  var action: () -> Void

  @_spi(Internal) public init(
    title: String,
    role: ButtonRole? = nil,
    action: @escaping () -> Void
  ) {
    id = UUID()
    self.title = title
    self.role = role
    self.action = action
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

@_spi(Internal) public extension IMGLY where Wrapped: View {
  func alert(_ alert: Binding<AlertState?>) -> some View {
    wrapped.alert(
      alert.wrappedValue.map { Text($0.title) } ?? Text(verbatim: ""),
      isPresented: Binding(alert),
      presenting: alert.wrappedValue,
      actions: { alert in
        ForEach(alert.buttons) { button in
          Button(button.title, role: button.role, action: button.action)
        }
      },
      message: { alert in
        alert.message.map { Text($0) }
      }
    )
  }
}

extension Binding {
  init(_ base: Binding<(some Any)?>) where Value == Bool {
    self = base._isPresent
  }
}

private extension Optional {
  var _isPresent: Bool {
    get { self != nil }
    set {
      guard !newValue else { return }
      self = nil
    }
  }
}
