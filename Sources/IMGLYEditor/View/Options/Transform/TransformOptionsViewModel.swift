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
        let groups = try? await withThrowingTaskGroup(of: [String].self) { group in
          for source in sources {
            group.addTask {
              try await self.interactor.getGroups(sourceID: source.id)
            }
          }

          var allGroups = [String]()
          for try await _group in group {
            allGroups.append(contentsOf: _group)
          }
          return allGroups
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
          for source in sources {
            group.addTask {
              let assets = try await self.interactor.findAssets(
                sourceID: source.id,
                query: .init(query: nil, page: 1, groups: [id], perPage: 1)
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
              case .freeAspectRatio, .fixedAspectRatio:
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
        let width = try engine.block.getWidth(pageID)
        let height = try engine.block.getHeight(pageID)
        let dpi = try engine.block.getFloat(scene, property: "scene/dpi")
        let pixelFactor = try engine.block.getFloat(scene, property: "scene/pixelScaleFactor")

        dimensions = PageDimensions(
          width: CGFloat(width),
          height: CGFloat(height),
          designUnit: designUnit,
          dpi: CGFloat(dpi),
          pixelScale: CGFloat(pixelFactor)
        )
      } catch {
        return
      }
    }
  }
}
