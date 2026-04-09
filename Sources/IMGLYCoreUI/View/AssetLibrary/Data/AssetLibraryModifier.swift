import Foundation

// MARK: - CategoryModifier

/// A helper to modify an array of asset library categories.
///
/// Similar to `ArrayModifier` but works with string-based IDs for asset library types.
@MainActor
public class CategoryModifier {
  private var toAddLast: [AssetLibraryCategory] = []
  private var toAddFirst: [AssetLibraryCategory] = []
  private var toAddAfter: [String: [AssetLibraryCategory]] = [:]
  private var toAddBefore: [String: [AssetLibraryCategory]] = [:]
  private var toReplace: [String: [AssetLibraryCategory]] = [:]
  private var toRemove: Set<String> = []
  private var sectionModifiers: [String: (SectionModifier) -> Void] = [:]

  /// Creates a category modifier.
  public init() {}

  /// Appends categories at the end.
  /// - Parameter categories: The categories to append.
  public func addLast(_ categories: AssetLibraryCategory...) {
    toAddLast.append(contentsOf: categories)
  }

  /// Prepends categories at the start.
  /// - Parameter categories: The categories to prepend.
  public func addFirst(_ categories: AssetLibraryCategory...) {
    toAddFirst.insert(contentsOf: categories, at: 0)
  }

  /// Inserts categories after the category with the specified ID.
  /// - Parameters:
  ///   - id: The ID of the category after which to insert.
  ///   - categories: The categories to insert.
  /// - Note: An error will be thrown if no category exists with the provided ID.
  public func addAfter(id: String, _ categories: AssetLibraryCategory...) {
    toAddAfter[id, default: []].insert(contentsOf: categories, at: 0)
  }

  /// Inserts categories before the category with the specified ID.
  /// - Parameters:
  ///   - id: The ID of the category before which to insert.
  ///   - categories: The categories to insert.
  /// - Note: An error will be thrown if no category exists with the provided ID.
  public func addBefore(id: String, _ categories: AssetLibraryCategory...) {
    toAddBefore[id, default: []].append(contentsOf: categories)
  }

  /// Replaces the category with the specified ID.
  /// - Parameters:
  ///   - id: The ID of the category to replace.
  ///   - categories: The categories to use as replacement (can be multiple or empty to remove).
  /// - Note: An error will be thrown if no category exists with the provided ID.
  public func replace(id: String, _ categories: AssetLibraryCategory...) {
    toReplace[id] = categories
  }

  /// Removes the category with the specified ID.
  /// - Parameter id: The ID of the category to remove.
  /// - Note: An error will be thrown if no category exists with the provided ID.
  public func remove(id: String) {
    toRemove.insert(id)
  }

  /// Modifies the sections of the category with the specified ID.
  /// - Parameters:
  ///   - id: The ID of the category whose sections to modify.
  ///   - modify: A closure that receives a section modifier.
  public func modifySections(of id: String, _ modify: @escaping (SectionModifier) -> Void) {
    sectionModifiers[id] = modify
  }

  /// Applies all modifications to the given categories.
  /// - Parameter categories: The categories to modify.
  /// - Returns: The modified categories.
  /// - Throws: An error if any referenced category ID doesn't exist.
  @_spi(Internal)
  public func apply(to categories: [AssetLibraryCategory]) throws -> [AssetLibraryCategory] {
    var result: [AssetLibraryCategory] = []

    // Track which IDs we've seen
    var processedIds = Set<String>()

    // Add first items
    result.append(contentsOf: toAddFirst)

    // Process existing items
    for var category in categories {
      processedIds.insert(category.id)
      let id = category.id

      // Skip if removed
      if toRemove.remove(id) != nil {
        continue
      }

      // Add before items
      if let before = toAddBefore.removeValue(forKey: id) {
        result.append(contentsOf: before)
      }

      // Apply section modifications to this category
      if let sectionModify = sectionModifiers[id] {
        let sectionModifier = SectionModifier()
        sectionModify(sectionModifier)
        category.sections = try sectionModifier.apply(to: category.sections)
      }

      // Replace or keep
      if let replacement = toReplace.removeValue(forKey: id) {
        result.append(contentsOf: replacement)
      } else {
        result.append(category)
      }

      // Add after items
      if let after = toAddAfter.removeValue(forKey: id) {
        result.append(contentsOf: after)
      }
    }

    // Add last items
    result.append(contentsOf: toAddLast)

    // Check for unprocessed operations
    if let id = toRemove.first {
      throw AssetLibraryModifierError(
        operation: "remove",
        id: id,
        type: "category",
      )
    }
    if let id = toAddBefore.keys.first {
      throw AssetLibraryModifierError(
        operation: "addBefore",
        id: id,
        type: "category",
      )
    }
    if let id = toAddAfter.keys.first {
      throw AssetLibraryModifierError(
        operation: "addAfter",
        id: id,
        type: "category",
      )
    }
    if let id = toReplace.keys.first {
      throw AssetLibraryModifierError(
        operation: "replace",
        id: id,
        type: "category",
      )
    }

    return result
  }
}

// MARK: - SectionModifier

/// A helper to modify an array of asset library sections within a category.
@MainActor
public class SectionModifier {
  private var toAddLast: [AssetLibrarySection] = []
  private var toAddFirst: [AssetLibrarySection] = []
  private var toAddAfter: [String: [AssetLibrarySection]] = [:]
  private var toAddBefore: [String: [AssetLibrarySection]] = [:]
  private var toReplace: [String: [AssetLibrarySection]] = [:]
  private var toRemove: Set<String> = []

  /// Creates a section modifier.
  public init() {}

  /// Appends sections at the end.
  /// - Parameter sections: The sections to append.
  public func addLast(_ sections: AssetLibrarySection...) {
    toAddLast.append(contentsOf: sections)
  }

  /// Prepends sections at the start.
  /// - Parameter sections: The sections to prepend.
  public func addFirst(_ sections: AssetLibrarySection...) {
    toAddFirst.insert(contentsOf: sections, at: 0)
  }

  /// Inserts sections after the section with the specified ID.
  /// - Parameters:
  ///   - id: The ID of the section after which to insert.
  ///   - sections: The sections to insert.
  /// - Note: An error will be thrown if no section exists with the provided ID.
  public func addAfter(id: String, _ sections: AssetLibrarySection...) {
    toAddAfter[id, default: []].insert(contentsOf: sections, at: 0)
  }

  /// Inserts sections before the section with the specified ID.
  /// - Parameters:
  ///   - id: The ID of the section before which to insert.
  ///   - sections: The sections to insert.
  /// - Note: An error will be thrown if no section exists with the provided ID.
  public func addBefore(id: String, _ sections: AssetLibrarySection...) {
    toAddBefore[id, default: []].append(contentsOf: sections)
  }

  /// Replaces the section with the specified ID.
  /// - Parameters:
  ///   - id: The ID of the section to replace.
  ///   - sections: The sections to use as replacement (can be multiple or empty to remove).
  /// - Note: An error will be thrown if no section exists with the provided ID.
  public func replace(id: String, _ sections: AssetLibrarySection...) {
    toReplace[id] = sections
  }

  /// Removes the section with the specified ID.
  /// - Parameter id: The ID of the section to remove.
  /// - Note: An error will be thrown if no section exists with the provided ID.
  public func remove(id: String) {
    toRemove.insert(id)
  }

  /// Applies all modifications to the given sections.
  /// - Parameter sections: The sections to modify.
  /// - Returns: The modified sections.
  /// - Throws: An error if any referenced section ID doesn't exist.
  @_spi(Internal)
  public func apply(to sections: [AssetLibrarySection]) throws -> [AssetLibrarySection] {
    var result: [AssetLibrarySection] = []

    // Add first items
    result.append(contentsOf: toAddFirst)

    // Process existing items
    for section in sections {
      let id = section.id

      // Skip if removed
      if toRemove.remove(id) != nil {
        continue
      }

      // Add before items
      if let before = toAddBefore.removeValue(forKey: id) {
        result.append(contentsOf: before)
      }

      // Replace or keep
      if let replacement = toReplace.removeValue(forKey: id) {
        result.append(contentsOf: replacement)
      } else {
        result.append(section)
      }

      // Add after items
      if let after = toAddAfter.removeValue(forKey: id) {
        result.append(contentsOf: after)
      }
    }

    // Add last items
    result.append(contentsOf: toAddLast)

    // Check for unprocessed operations
    if let id = toRemove.first {
      throw AssetLibraryModifierError(
        operation: "remove",
        id: id,
        type: "section",
      )
    }
    if let id = toAddBefore.keys.first {
      throw AssetLibraryModifierError(
        operation: "addBefore",
        id: id,
        type: "section",
      )
    }
    if let id = toAddAfter.keys.first {
      throw AssetLibraryModifierError(
        operation: "addAfter",
        id: id,
        type: "section",
      )
    }
    if let id = toReplace.keys.first {
      throw AssetLibraryModifierError(
        operation: "replace",
        id: id,
        type: "section",
      )
    }

    return result
  }
}

// MARK: - Error

/// An error thrown when an asset library modification fails.
public struct AssetLibraryModifierError: LocalizedError {
  let operation: String
  let id: String
  let type: String

  public var errorDescription: String? {
    "The '\(operation)' operation was invoked with \(type) id '\(id)' " +
      "which does not exist in the source array or is already removed via remove API."
  }
}
