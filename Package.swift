// swift-tools-version: 5.8
import PackageDescription

let package = Package(
  name: "IMGLYUI",
  platforms: [.iOS(.v16)],
  products: [
    // Comment out these products for development to fix SwiftUI previews inside this package
    .library(name: "IMGLYEditor", targets: ["IMGLYEditor"]),
    .library(name: "IMGLYDesignEditor", targets: ["IMGLYDesignEditor"]),
    .library(name: "IMGLYApparelEditor", targets: ["IMGLYApparelEditor"]),
    .library(name: "IMGLYPostcardEditor", targets: ["IMGLYPostcardEditor"]),

    // Default product which includes all modules
    .library(name: "IMGLYUI",
             targets: [
               "IMGLYCore",
               "IMGLYCoreUI",
               "IMGLYEditor",
               "IMGLYDesignEditor",
               "IMGLYApparelEditor",
               "IMGLYPostcardEditor"
             ])
  ],
  dependencies: [
    .package(url: "https://github.com/imgly/IMGLYEngine-swift.git", exact: "1.22.0"),
    .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", exact: "0.1.4"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", exact: "7.6.2")
  ],
  targets: [
    .target(
      name: "IMGLYCore",
      dependencies: [.product(name: "IMGLYEngine", package: "IMGLYEngine-swift")]
    ),
    .target(
      name: "IMGLYCoreUI",
      dependencies: [
        .target(name: "IMGLYCore"),
        .product(name: "Introspect", package: "SwiftUI-Introspect"),
        .product(name: "Kingfisher", package: "Kingfisher")
      ]
    ),
    .target(
      name: "IMGLYEditor",
      dependencies: [.target(name: "IMGLYCoreUI")]
    ),
    .target(
      name: "IMGLYDesignEditor",
      dependencies: [.target(name: "IMGLYEditor")],
      resources: [.process("Resources")]
    ),
    .target(
      name: "IMGLYApparelEditor",
      dependencies: [.target(name: "IMGLYEditor")],
      resources: [.process("Resources")]
    ),
    .target(
      name: "IMGLYPostcardEditor",
      dependencies: [.target(name: "IMGLYEditor")],
      resources: [.process("Resources")]
    )
  ]
)

for target in package.targets {
  var settings = target.swiftSettings ?? []
  // Uncomment for development
//  settings.append(.enableExperimentalFeature("StrictConcurrency")) // Xcode 15
//  settings.append(.unsafeFlags(["-strict-concurrency=complete"])) // Xcode 14, don't use `unsafeFlags` in production!
  target.swiftSettings = settings
}
