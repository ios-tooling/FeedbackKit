// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Bumped from 5.9 to 6.0 so the manifest can name .iOS(.v18) / .macOS(.v15) (TapeDeck's floor).
// Language mode is pinned to Swift 5 below to avoid an unrelated Swift 6 concurrency migration.

import PackageDescription

let package = Package(
    name: "FeedbackKit",
    platforms: [
                .macOS(.v15),
                .iOS(.v18)
         ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FeedbackKit",
            targets: ["FeedbackKit"]),
    ],
    dependencies: [
		.package(url: "https://github.com/ios-tooling/Suite.git", from: "1.4.13"),
		.package(url: "https://github.com/ios-tooling/CrossPlatformKit.git", from: "1.0.13"),
		.package(url: "https://github.com/ios-tooling/Chronicle.git", from: "0.0.29"),
		.package(url: "https://github.com/ios-tooling/Achtung.git", from: "0.5.4"),
		.package(url: "https://github.com/ios-tooling/TapeDeck.git", from: "0.4.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FeedbackKit", dependencies: [
						.product(name: "Suite", package: "Suite"),
						.product(name: "CrossPlatformKit", package: "CrossPlatformKit"),
						.product(name: "Chronicle", package: "Chronicle"),
						.product(name: "Achtung", package: "Achtung"),
						.product(name: "TapeDeck", package: "TapeDeck"),
            ]),
        .testTarget(
            name: "FeedbackKitTests",
            dependencies: ["FeedbackKit"]),
    ],
    swiftLanguageModes: [.v5]
)
