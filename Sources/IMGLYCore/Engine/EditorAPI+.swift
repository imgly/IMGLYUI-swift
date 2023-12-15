import IMGLYEngine

@_spi(Internal) public extension EditorAPI {
  func resetHistory() throws {
    let oldHistory = getActiveHistory()
    let newHistory = createHistory()
    setActiveHistory(newHistory)
    destroyHistory(oldHistory)
    try addUndoStep()
  }
}
