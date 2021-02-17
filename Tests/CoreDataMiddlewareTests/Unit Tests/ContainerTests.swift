//
//  File.swift
//  
//
//  Created by Bo Weber on 10.02.21.
//

import XCTest
import CoreData
import Combine
@testable import CoreDataMiddleware

class ContainerTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        self.cancellables = []
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
    }
    
    func testContainerPublisherFromLoadedState() throws {
        let state = CoreDataContainer
            .ContainerState
            .loaded(try XCTUnwrap(.testContainer))
    
        let expectSuccess = expectation(description: "Successful")
        let container = CoreDataContainer(state: state)
        
        container
            .containerPublisher()
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { _ in
                expectSuccess.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectSuccess], timeout: 1, enforceOrder: true)
    }
    
    func testContainerPublisherFromFailingState() throws {
        let state = CoreDataContainer
            .ContainerState
            .loadingFailure(
                error: NSError.testError(),
                container: try XCTUnwrap(.testContainer),
                publisher: { _ in Fail.testFailure(outputType: NSPersistentContainer.self) }
            )
        
        let expectFailure = expectation(description: "Failure")
        let container = CoreDataContainer(state: state)
        
        container
            .containerPublisher()
            .sink { completion in
                switch completion {
                case .failure:
                    if case .loadingFailure(error: _, container: _, publisher: _) = container.state {
                        expectFailure.fulfill()
                    } else {
                        XCTFail()
                    }
                case .finished:
                    XCTFail()
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
        
        wait(for: [expectFailure], timeout: 1, enforceOrder: true)
    }

    func testSetupFailureAfterLoading() throws {
        let expectFailure = expectation(description: "Failure")
        
        let state = CoreDataContainer.ContainerState(
            try XCTUnwrap(.testContainer)) { container in
            Just(container)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } configure: { _ in
            throw NSError.testError()
        }

        let container = CoreDataContainer(state: state)
        
        container
            .containerPublisher()
            .sink { completion in
                switch completion {
                case .failure:
                    if case .loadingFailure(error: _, container: _, publisher: _) = container.state {
                        expectFailure.fulfill()
                    } else {
                        XCTFail()
                    }
                case .finished:
                    XCTFail()
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
        
        wait(for: [expectFailure], timeout: 1, enforceOrder: true)
    }
    
    func testLoadingFailure() throws {
        let expectFailure = expectation(description: "Failure")
        
        let state = CoreDataContainer.ContainerState(
            try XCTUnwrap(.testContainer), publisher:  { container in
                Fail.testFailure(outputType: NSPersistentContainer.self)
            })

        let container = CoreDataContainer(state: state)
        
        container
            .containerPublisher()
            .sink { completion in
                switch completion {
                case .failure:
                    if case .loadingFailure(error: _, container: _, publisher: _) = container.state {
                        expectFailure.fulfill()
                    } else {
                        XCTFail()
                    }
                case .finished:
                    XCTFail()
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
        
        wait(for: [expectFailure], timeout: 1, enforceOrder: true)
    }

    func testSuccessfulMockedLoading() throws {
        let state = CoreDataContainer.ContainerState(
            try XCTUnwrap(.testContainer),
            publisher: { container in
                Just(container)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        )
        let expectSuccess = expectation(description: "Successful")
        let container = CoreDataContainer(state: state)
        
        container
            .containerPublisher()
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { _ in
                expectSuccess.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectSuccess], timeout: 1, enforceOrder: true)
    }
    
    func testSuccessfulLoading() throws {
        let state = CoreDataContainer.ContainerState(
            try XCTUnwrap(.testContainer)
        )
        let expectSuccess = expectation(description: "Successful")
        let container = CoreDataContainer(state: state)
        
        container
            .containerPublisher()
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { _ in
                expectSuccess.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectSuccess], timeout: 1, enforceOrder: true)
    }
    
}
