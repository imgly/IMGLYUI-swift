/// A result builder for building arrays.
@resultBuilder
public enum ArrayBuilder<Element> {
  /// The type of expressions.
  public typealias Expression = Element
  /// The type of components.
  public typealias Component = [Element]

  public static func buildBlock(_ components: Component...) -> Component {
    components.flatMap(\.self)
  }

  public static func buildExpression(_ expression: Expression) -> Component {
    [expression]
  }

  public static func buildExpression(_ expression: [Expression]) -> Component {
    expression
  }

  public static func buildOptional(_ component: Component?) -> Component {
    component ?? []
  }

  public static func buildEither(first component: Component) -> Component {
    component
  }

  public static func buildEither(second component: Component) -> Component {
    component
  }

  public static func buildArray(_ components: [Component]) -> Component {
    components.flatMap(\.self)
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
