//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import Foundation
import CoreData
import Combine

/// A wrapper for a `NSPersistentContainer`, which can also be initilized with a `NSPersistentCloudKitContainer`.
public class CoreDataContainer {
    var state: ContainerState
    
    init(state: ContainerState) {
        self.state = state
    }
    
    /// Initializes a core data container with the given `Container`.
    /// - Parameters:
    ///   - container: This can be a `NSPersistentContainer` or a `NSPersistentCloudKitContainer`
    ///   - configure: A failable execution block, which is executed after the stores are loaded.
    public init(
        _ container: NSPersistentContainer,
        configure: ((NSPersistentContainer) throws -> Void)? = nil
    ) {
        self.state = ContainerState(
            container,
            configure: configure
        )
    }

    func containerPublisher() -> AnyPublisher<NSPersistentContainer, Error> {
        switch state {
        case let .initial(container: container, publisher: makePublisher):
            return makePublisher(container)
                .handleEvents(receiveOutput: { [weak self] container in
                    guard let self = self else { return }
                    self.state = .loaded(container)
                }, receiveCompletion: { [weak self] completion in
                    guard case let .failure(error) = completion, let self = self else { return }
                    self.state = .loadingFailure(error: error, container: container, publisher: makePublisher)
                })
                .eraseToAnyPublisher()
        case .loaded(let container):
            return Just(container)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .loadingFailure(error: let error, container: _,  publisher: _):
            return Fail(outputType: NSPersistentContainer.self, failure: error)
                .eraseToAnyPublisher()
        }
    }
    
    enum ContainerState {
        case initial(container: NSPersistentContainer, publisher: (NSPersistentContainer) -> AnyPublisher<NSPersistentContainer, Error>)
        case loadingFailure(error: Error, container: NSPersistentContainer, publisher: (NSPersistentContainer) -> AnyPublisher<NSPersistentContainer, Error>)
        case loaded(NSPersistentContainer)
        
        init(
            _ container: NSPersistentContainer,
            publisher: ((NSPersistentContainer) -> AnyPublisher<NSPersistentContainer, Error>)? = nil,
            configure: ((NSPersistentContainer) throws -> Void)? = nil
        ) {
            self = .initial(container: container, publisher: { container in
                (
                    publisher.map { $0(container) } ??
                        container
                        .loadPersistentStores()
                        .map { container }
                        .eraseToAnyPublisher()
                )
                .tryMap { loadedContainer in
                    try configure.map { try $0(loadedContainer) }
                    return loadedContainer
                }
                .eraseToAnyPublisher()
            })
        }
    }
}

