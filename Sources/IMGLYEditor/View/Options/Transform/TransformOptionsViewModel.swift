import Combine
import Foundation
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

extension TransformOptions {
  @MainActor
  class ViewModel: ObservableObject {
    let interactor: Interactor
    let sources: [AssetLoader.SourceData]

    @Published private(set) var groups: [String] = []
    @Published private(set) var assetGridHeight: CGFloat = 120
    @Published private(set) var dimensions: PageDimensions?
    @Published var query: AssetLoader.QueryData = .init()
    @Published var alertPresented: Bool = false
    @Published var selectedGroup: String? {
      didSet {
        if let newValue = selectedGroup {
          updateAssetGrid(for: newValue)
        }
      }
    }

    private var subscription: Task<Void, Never>?

    init(interactor: Interactor, sources: [AssetLoader.SourceData]) {
      self.interactor = interactor
      self.sources = sources

      setupPageDimensionSubscription()
    }

    deinit { subscription?.cancel() }

    func loadGroups() {
      Task {
        let groups = try? await withThrowingTaskGroup(of: (Int, [String]).self) { group in
          let interactor = self.interactor
          for (index, source) in sources.enumerated() {
            group.addTask {
              (index, try await interactor.getGroups(sourceID: source.id))
            }
          }

          // The first source owns the initial category, regardless of which request finishes first.
          var allGroups = Array(repeating: [String](), count: sources.count)
          for try await (index, groups) in group {
            allGroups[index] = groups
          }
          return allGroups.flatMap(\.self)
        }

        guard let groups, let initialGroup = groups.first else { return }
        self.groups = groups
        selectedGroup = initialGroup
        updateAssetGrid(for: initialGroup)
      }
    }

    private func setupPageDimensionSubscription() {
      updatePageDimensions()

      if let pageID = try? interactor.engine?.getPage(interactor.page), let engine = interactor.engine {
        subscription = Task { [weak self] in
          for await events in engine.event.subscribe(to: [pageID]) {
            for event in events where event.type == .updated {
              self?.updatePageDimensions()
              break
            }
          }
        }
      }
    }

    private func updateAssetGrid(for id: String) {
      Task {
        let height: CGFloat = try await withThrowingTaskGroup(of: AssetLoader.Asset?.self) { group in
          let interactor = self.interactor
          for source in sources {
            group.addTask {
              let assets = try await interactor.findAssets(
                sourceID: source.id,
                query: .init(query: nil, page: 1, groups: [id], perPage: 1),
              )
              if let firstAsset = assets.assets.first {
                return AssetLoader.Asset(sourceID: source.id, result: firstAsset)
              } else {
                return nil
              }
            }
          }

          for try await asset in group {
            if let asset {
              switch asset.result.payload?.transformPreset {
              case .freeAspectRatio, .fixedAspectRatio, .contentAspectRatio:
                return 72
              default:
                return 120
              }
            }
          }

          return 120
        }

        await MainActor.run {
          withAnimation {
            self.assetGridHeight = height
          }
        }
        query = .init(groups: [id])
      }
    }

    private func updatePageDimensions() {
      guard let engine = interactor.engine else { return }
      do {
        guard let scene = try engine.scene.get() else { return }
        let pageID = try engine.getPage(interactor.page)
        let designUnit = try engine.scene.getDesignUnit()
        let fontUnit = try engine.scene.getFontSizeUnit()
        let width = try engine.block.getWidth(pageID)
        let height = try engine.block.getHeight(pageID)
        let dpi = try engine.block.getFloat(scene, property: "scene/dpi")
        let pixelFactor = try engine.block.getFloat(scene, property: "scene/pixelScaleFactor")

        dimensions = PageDimensions(
          width: CGFloat(width),
          height: CGFloat(height),
          designUnit: designUnit,
          fontUnit: fontUnit,
          dpi: CGFloat(dpi),
          pixelScale: CGFloat(pixelFactor),
        )
      } catch {
        return
      }
    }
  }
}
