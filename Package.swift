// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "IMGLYUI",
  platforms: [.iOS(.v16)],
  products: [
    // Comment out these products for development to fix SwiftUI previews inside this package
    .library(name: "IMGLYCamera", targets: ["IMGLYCamera"]),
    .library(name: "IMGLYDesignEditor", targets: ["IMGLYDesignEditor"]),
    .library(name: "IMGLYVideoEditor", targets: ["IMGLYVideoEditor"]),
    .library(name: "IMGLYApparelEditor", targets: ["IMGLYApparelEditor"]),
    .library(name: "IMGLYPostcardEditor", targets: ["IMGLYPostcardEditor"]),

    // Default product which includes all modules
    .library(name: "IMGLYUI",
             targets: [
               "IMGLYCore",
               "IMGLYCoreUI",
               "IMGLYCamera",
               "IMGLYEditor",
               "IMGLYDesignEditor",
               "IMGLYVideoEditor",
               "IMGLYApparelEditor",
               "IMGLYPostcardEditor"
             ])
  ],
  dependencies: [
    .package(url: "https://github.com/imgly/IMGLYEngine-swift.git", exact: "1.24.0-rc.0"),
    .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "1.1.2"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.6.2")
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
        .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect"),
        .product(name: "Kingfisher", package: "Kingfisher")
      ]
    ),
    .target(
      name: "IMGLYCamera",
      dependencies: [.target(name: "IMGLYCoreUI")]
    ),
    .target(
      name: "IMGLYEditor",
      dependencies: [.target(name: "IMGLYCamera")]
    ),
    .target(
      name: "IMGLYDesignEditor",
      dependencies: [.target(name: "IMGLYEditor")],
      resources: [.process("Resources")]
    ),
    .target(
      name: "IMGLYVideoEditor",
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
