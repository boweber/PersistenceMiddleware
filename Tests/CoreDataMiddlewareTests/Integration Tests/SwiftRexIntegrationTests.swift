//
//  File.swift
//  
//
//  Created by Bo Weber on 15.02.21.
//

import XCTest
import Foundation
import PersistenceMiddleware
import CoreDataMiddleware
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
        savePublisher: ((NSPersistentContainer, SongTitleRequest.Element) -> AnyPublisher<Void, CoreDataError>)? = nil,
        deletePublisher: ((NSPersistentContainer, SongTitleRequest.Element) -> AnyPublisher<Void, CoreDataError>)? = nil,
        requestPublisher: ((NSPersistentContainer, SongTitleRequest) -> AnyPublisher<PersistenceFetchResult<SongTitleRequest.Element>, CoreDataError>)? = nil
    ) throws -> ReduxStoreBase<AppAction, AppState> {
        let testContainer = try XCTUnwrap(NSPersistentContainer.testContainer)
        let container = CoreDataContainer(testContainer)
        let middleware: AnyMiddleware<AppAction, AppAction, AppState> = (
            CoreDataController<SongArtistRequest>(container)
                .makeMiddleware()
                .lift(
                    inputAction: \.artist,
                    outputAction: { AppAction.artist($0) },
                    state: \.artist
                )
                <>
                CoreDataController<SongTitleRequest>(
                    container,
                    savePublisher: savePublisher,
                    deletePublisher: deletePublisher,
                    requestPublisher: requestPublisher
                )
                .makeMiddleware()
                .lift(
                    inputAction: \.title,
                    outputAction: { AppAction.title($0) },
                    state: \.title
                )
        )
        .eraseToAnyMiddleware()
        
        let appReducer: Reducer<AppAction, AppState> = {
            CoreDataController<SongArtistRequest>
                .makeReducer()
                .lift(action: \AppAction.artist, state: \AppState.artist)
                <>
                CoreDataController<SongTitleRequest>
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
}