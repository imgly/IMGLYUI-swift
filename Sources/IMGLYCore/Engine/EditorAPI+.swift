import IMGLYEngine

@_spi(Internal) public extension EditorAPI {
  func resetHistory() throws {
    let oldHistory = getActiveHistory()
    let newHistory = createHistory()
    setActiveHistory(newHistory)
    destroyHistory(oldHistory)
    try addUndoStep()
  }

  func setRoleButPreserveGlobalScopes(_ role: String) throws {
    let scopes = try Dictionary(uniqueKeysWithValues: findAllScopes().map {
      try ($0, getGlobalScope(key: $0))
    })
    try setRole(role)
    try scopes.forEach { key, value in
      try setGlobalScope(key: key, value: value)
    }
  }
}
