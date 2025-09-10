import SwiftUI

/// A wrapper for SwiftUI GridItem arrays that provides Equatable conformance.
///
/// This struct enables comparison of GridItem arrays for equality, which is useful
/// for SwiftUI view diffing and performance optimization. It provides compatibility
/// across SDK versions, using native Equatable support when available (SwiftUI 6.0+)
/// and a custom implementation for earlier SDK versions.
struct AssetGridItems: Equatable {
  let gridItems: [GridItem]

  static func == (lhs: AssetGridItems, rhs: AssetGridItems) -> Bool {
    #if swift(>=6.2)
      if #available(iOS 26.0, *) {
        return lhs.gridItems == rhs.gridItems
      }
    #endif
    return lhs.gridItems.count == rhs.gridItems.count && zip(lhs.gridItems, rhs.gridItems).allSatisfy { l, r in
      l.spacing == r.spacing &&
        l.alignment == r.alignment &&
        gridItemSizeEqual(l.size, r.size)
    }
  }

  private static func gridItemSizeEqual(_ l: GridItem.Size, _ r: GridItem.Size) -> Bool {
    switch (l, r) {
    case let (.fixed(a), .fixed(b)):
      a == b
    case let (.flexible(minA, maxA), .flexible(minB, maxB)):
      minA == minB && maxA == maxB
    case let (.adaptive(minA, maxA), .adaptive(minB, maxB)):
      minA == minB && maxA == maxB
    default:
      false
    }
  }
}
