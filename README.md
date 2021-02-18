# PersistenceMiddleware

This package provides middlewares for [SwiftRex](https://github.com/SwiftRex/SwiftRex) handling persistence related actions. 

**Note**: The current implementation only supports *Core Data*.

## Modular structure

The package currently contains two targets *PersistenceMiddleware* and *CoreDataMiddleware*. The core parts (i.e. middleware, reducer, action and state), which interact with *SwiftRex*, are part of *PersistenceMiddleware*. For more information see [PersistenceMiddleware](Sources/PersistenceMiddleware/README.md). The *CoreDataMiddleware* connects the core parts from *PersistenceMiddleware* to the *Core Data* framework and is managing the interaction with the database. You can save, delete and request any element that conforms to the `CoreDataPersistable` protocol. For more, see [CoreDataMiddleware](Sources/CoreDataMiddleware/README.md).

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

## TODO

- Add actions to cancel the current save/delete process ?!
- Add action handling *move element from index to index* 
- Add multiple states for different requests ?!  
    This could be archived with a dictionary (e.g. `[Request.Token: RequestState]`) instead of just `RequestState` as the request parameter type. 
- Implement section support
- Implement cache support (reloading previously fetched elements)
- Implement error resolving functionality
- Improve the documentation.