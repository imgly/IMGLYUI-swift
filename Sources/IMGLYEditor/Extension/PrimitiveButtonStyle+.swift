import SwiftUI

extension PrimitiveButtonStyle where Self == BottomBarButtonStyle {
  static var bottomBar: Self { Self() }
}

extension PrimitiveButtonStyle where Self == OptionButtonStyle {
  static var option: Self { Self() }
}

extension PrimitiveButtonStyle where Self == FloatingActionButtonStyle {
  static var fab: Self { Self() }
}
