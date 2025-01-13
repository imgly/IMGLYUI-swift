@resultBuilder
@_spi(Unstable) public enum ArrayBuilder<Element> {
  @_spi(Unstable) public typealias Expression = Element
  @_spi(Unstable) public typealias Component = [Element]

  @_spi(Unstable) public static func buildBlock(_ components: Component...) -> Component {
    components.flatMap { $0 }
  }

  @_spi(Unstable) public static func buildExpression(_ expression: Expression) -> Component {
    [expression]
  }

  @_spi(Unstable) public static func buildExpression(_ expression: [Expression]) -> Component {
    expression
  }

  @_spi(Unstable) public static func buildOptional(_ component: Component?) -> Component {
    component ?? []
  }

  @_spi(Unstable) public static func buildEither(first component: Component) -> Component {
    component
  }

  @_spi(Unstable) public static func buildEither(second component: Component) -> Component {
    component
  }

  @_spi(Unstable) public static func buildArray(_ components: [Component]) -> Component {
    components.flatMap { $0 }
  }
}

func withArrayBuilder<T>(@ArrayBuilder<T> elements: () -> [T]) -> [T] {
  elements()
}

import SwiftUI

#Preview {
  // swiftformat:disable redundantLet
  // swiftlint:disable:next redundant_discardable_let
  let _ = withArrayBuilder {
    1
    [2, 3]
    if true {
      4
    }
    if true {
      5
    } else {
      6
    }
    switch "7" {
    case "7": 7
    case "8": 8
    default: 9
    }
    for i in 0 ... 9 {
      i
    }
  }
  return EmptyView()
}
