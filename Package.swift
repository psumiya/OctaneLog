// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OctaneLog",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OctaneLogCore",
            targets: ["OctaneLogCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/google/generative-ai-swift", from: "0.5.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OctaneLogCore",
            dependencies: [
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift")
            ],
            path: ".",
            exclude: ["App", "Resources", "README.md", "Package.swift", "OctaneRunner", "Tests", "Verification"],
            sources: ["Core", "Domains", "Features"]
        ),
        .testTarget(
            name: "OctaneLogTests",
            dependencies: ["OctaneLogCore"],
            path: "Tests"
        ),
        .executableTarget(
            name: "Verification",
            dependencies: ["OctaneLogCore"],
            path: "Verification"
        )
    ]
)
