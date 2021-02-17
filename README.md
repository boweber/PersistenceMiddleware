# PersistenceMiddleware

This package provides middlewares for [SwiftRex](https://github.com/SwiftRex/SwiftRex) handling persistence related actions.

## PersistenceMiddleware
The `PersistenceMiddleware` contains the core functionality for every persistence related action.
For more information see [PersistenceMiddleware](Sources/PersistenceMiddleware/README.md).

## CoreDataMiddleware
The `CoreDataMiddleware` contains every *Core Data* related functionality.
For more information see [CoreDataMiddleware](Sources/CoreDataMiddleware/README.md).

## Installation

```swift
// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "MyApp",
  platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
  products: [
    .executable(name: "MyApp", targets: ["MyApp"])
  ],
  dependencies: [
    .package(url: "https://github.com/boweber/PersistenceMiddleware", from: "0.1.0")
  ],
  targets: [
    .target(
      name: "MyApp",
      dependencies: [
        .product(name: "CoreDataMiddleware", package: "PersistenceMiddleware")
      ]
    )
  ]
)
```
