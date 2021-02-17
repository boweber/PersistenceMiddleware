// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PersistenceMiddleware",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "CoreDataMiddleware",
            targets: ["CoreDataMiddleware"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftRex/SwiftRex.git", from: "0.8.2")
    ],
    targets: [
        .target(
            name: "PersistenceMiddleware",
            dependencies: [.product(name: "CombineRex", package: "SwiftRex")],
            exclude: ["README.md"]
        ),
        .target(
            name: "CoreDataMiddleware",
            dependencies: ["PersistenceMiddleware", .product(name: "CombineRex", package: "SwiftRex")],
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "PersistenceMiddlewareTests",
            dependencies: ["PersistenceMiddleware"]
        ),
        .testTarget(
            name: "CoreDataMiddlewareTests",
            dependencies: ["CoreDataMiddleware"]
        )
    ]
)
