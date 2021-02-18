//
//  File.swift
//  
//
//  Created by Bo Weber on 15.02.21.
//

import XCTest
import Foundation
import PersistenceMiddleware
@testable import CoreDataMiddleware
import CoreData
import SwiftRex
import CombineRex
import Combine

class SwiftRexIntegrationTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        self.cancellables = []
    }
    
    override func tearDown() {
        self.cancellables.forEach { $0.cancel() }
    }

    func makeStore(
        customContainer: CoreDataContainer? = nil,
        savePublisher: ((NSPersistentContainer, SongTitle) -> AnyPublisher<Void, CoreDataError>)? = nil,
        deletePublisher: ((NSPersistentContainer, SongTitle) -> AnyPublisher<Void, CoreDataError>)? = nil,
        requestPublisher: ((NSPersistentContainer, SongTitle.Request) -> AnyPublisher<PersistenceFetchResult<SongTitle>, CoreDataError>)? = nil
    ) throws -> ReduxStoreBase<AppAction, AppState> {
        let testContainer = try XCTUnwrap(NSPersistentContainer.testContainer)
        let container = customContainer ?? CoreDataContainer(testContainer)
        let middleware: AnyMiddleware<AppAction, AppAction, AppState> = (
            CoreDataController<SongArtist>(container)
                .makeMiddleware()
                .lift(
                    inputAction: \.artist,
                    outputAction: AppAction.artist,
                    state: \.artist
                )
                <>
                CoreDataController<SongTitle>(
                    container,
                    savePublisher: savePublisher,
                    deletePublisher: deletePublisher,
                    requestPublisher: requestPublisher
                )
                .makeMiddleware()
                .lift(
                    inputAction: \.title,
                    outputAction: AppAction.title,
                    state: \.title
                )
        )
        .eraseToAnyMiddleware()
        
        let appReducer: Reducer<AppAction, AppState> = {
            CoreDataController<SongArtist>
                .makeReducer()
                .lift(action: \AppAction.artist, state: \AppState.artist)
                <>
                CoreDataController<SongTitle>
                .makeReducer()
                .lift(action: \AppAction.title, state: \AppState.title)
        }()
        
        return ReduxStoreBase<AppAction, AppState>(
            subject: .combine(initialValue: .init()),
            reducer: appReducer,
            middleware: middleware
        )
    }
    
    func testRequestElements() throws {
        let requestedElements = [SongTitle(title: "Blue Worlds"), SongTitle(title: "Self Care")]
        let store = try makeStore(requestPublisher: { _,_ in
            Just(.elements(requestedElements))
                .setFailureType(to: CoreDataError.self)
                .eraseToAnyPublisher()
        })
        
        let expectInitialState = expectation(description: "Initial")
        let expectLoadingState = expectation(description: "loading")
        let expectElements = expectation(description: "Received elements")
        
        store.statePublisher.sink { state in
            switch state.title.request {
            case .initial:
                expectInitialState.fulfill()
            case .loading:
                expectLoadingState.fulfill()
            case .received(let elements):
                XCTAssertEqual(elements,requestedElements)
                expectElements.fulfill()
            default: XCTFail()
            }
        }.store(in: &cancellables)
        
        store.dispatch(.title(.request(.all)))
        wait(for: [expectInitialState, expectLoadingState, expectElements], timeout: 1, enforceOrder: true)
    }
    
    func testFailLoadingStoresWhileRequestingElements() throws {
        let testContainer = try XCTUnwrap(NSPersistentContainer.testContainer)
        let container = CoreDataContainer(
            state: .initial(
                container: testContainer,
                publisher: { _ in Fail.testFailure(outputType: NSPersistentContainer.self) }
            )
        )
        let store = try makeStore(customContainer:  container)
        
        let expectInitialState = expectation(description: "Initial")
        let expectLoadingState = expectation(description: "loading")
        let expectLoadingFailure = expectation(description: "Failed")
        
        store.statePublisher.sink { state in
            switch state.title.request {
            case .initial:
                expectInitialState.fulfill()
            case .loading:
                expectLoadingState.fulfill()
            case .failed(error: let error, request: _):
                if case .containerError(_) = error {
                    expectLoadingFailure.fulfill()
                }
            default: XCTFail()
            }
        }.store(in: &cancellables)
        
        store.dispatch(.title(.request(.all)))
        wait(for: [expectInitialState, expectLoadingState, expectLoadingFailure], timeout: 1, enforceOrder: true)
    }
}
