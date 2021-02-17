import XCTest
import Combine
import CombineRex
@testable import SwiftRex
@testable import PersistenceMiddleware

final class PersistenceMiddlewareTests: XCTestCase {
    var cancellables: [AnyCancellable]!
    
    override func setUp() {
        cancellables = []
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
    }
    
    func makeStore(with controller: Controller)
    -> ReduxStoreBase<PersistenceAction<Song, NSError, SongRequest>, PersistenceState<Song, NSError, SongRequest>> {
        ReduxStoreBase(
            subject: .combine(initialValue: .initial),
            reducer: Controller.makeReducer(),
            middleware: controller.makeMiddleware()
        )
    }
    
    func testSuccessfulSave() {
        let store = makeStore(with: Controller())
        
        let expectInitialState = expectation(description: "Initial")
        let expectSaving = expectation(description: "Saving")
        let expectSuccess = expectation(description: "Successful")
        
        store.statePublisher.sink { state in
            switch state.persist {
            case .initial:
                expectInitialState.fulfill()
            case .processing:
                expectSaving.fulfill()
            case .succeeded:
                expectSuccess.fulfill()
            default: XCTFail()
            }
        }
        .store(in: &cancellables)
        store.dispatch(.save(.blueWorlds))
        wait(for: [expectInitialState, expectSaving, expectSuccess], timeout: 1, enforceOrder: true)
    }
    
    func testFailingSave() {
        let error = NSError(domain: "Test", code: 1, userInfo: [:])
        let store = makeStore(with: Controller(error: error))
        
        let expectInitialState = expectation(description: "Initial")
        let expectSaving = expectation(description: "Saving")
        let expectFailure = expectation(description: "Failed")
        
        store.statePublisher.sink { state in
            switch state.persist {
            case .initial:
                expectInitialState.fulfill()
            case .processing:
                expectSaving.fulfill()
            case .succeeded:
                XCTFail()
            case let .failed(error: failingError, element: song):
                XCTAssertEqual(error, failingError)
                XCTAssertEqual(song, Song.blueWorlds)
                expectFailure.fulfill()
            }
        }
        .store(in: &cancellables)
        store.dispatch(.save(.blueWorlds))
        wait(for: [expectInitialState, expectSaving, expectFailure], timeout: 1, enforceOrder: true)
    }
    
    func testSuccessfulDelete() {
        let store = makeStore(with: Controller())
        
        let expectInitialState = expectation(description: "Initial")
        let expectDeleting = expectation(description: "Deleting")
        let expectSuccess = expectation(description: "Successful")
        
        store.statePublisher.sink { state in
            switch state.delete {
            case .initial:
                expectInitialState.fulfill()
            case .processing:
                expectDeleting.fulfill()
            case .succeeded:
                expectSuccess.fulfill()
            default: XCTFail()
            }
        }
        .store(in: &cancellables)
        store.dispatch(.delete(.blueWorlds))
        wait(for: [expectInitialState, expectDeleting, expectSuccess], timeout: 1, enforceOrder: true)
    }
    
    func testFailingDelete() {
        let error = NSError(domain: "Test", code: 1, userInfo: [:])
        let store = makeStore(with: Controller(error: error))
        
        let expectInitialState = expectation(description: "Initial")
        let expectDeleting = expectation(description: "Deleting")
        let expectFailure = expectation(description: "Failed")
        
        store.statePublisher.sink { state in
            switch state.delete {
            case .initial:
                expectInitialState.fulfill()
            case .processing:
                expectDeleting.fulfill()
            case .succeeded:
                XCTFail()
            case let .failed(error: failingError, element: song):
                XCTAssertEqual(error, failingError)
                XCTAssertEqual(song, Song.blueWorlds)
                expectFailure.fulfill()
            }
        }
        .store(in: &cancellables)
        store.dispatch(.delete(.blueWorlds))
        wait(for: [expectInitialState, expectDeleting, expectFailure], timeout: 1, enforceOrder: true)
    }
    
    func testRequestElements() {
        let controller = Controller()
        let store = makeStore(with: controller)
        
        let expectInitialState = expectation(description: "Initial")
        let expectLoadingState = expectation(description: "loading")
        let expectElements = expectation(description: "Received elements")
        let expectCanceled = expectation(description: "Canceled")
        store
            .statePublisher
            .sink { state in
                switch state.request {
                case .initial:
                    expectInitialState.fulfill()
                case .loading:
                    expectLoadingState.fulfill()
                case .received:
                    expectElements.fulfill()
                case .canceled:
                    expectCanceled.fulfill()
                default: XCTFail()
                }
            }
            .store(in: &cancellables)
        store.dispatch(.request(.all))
        controller.requestPublisher.send(.elements([Song.blueWorlds]))
        wait(for: [expectInitialState, expectLoadingState, expectElements], timeout: 1, enforceOrder: true)
        store.dispatch(.cancelRequest)
        wait(for: [expectCanceled], timeout: 1)
    }
    
    func testFailRequestingElements() {
        let controller = Controller()
        let store = makeStore(with: controller)
        
        let expectInitialState = expectation(description: "Initial")
        let expectLoadingState = expectation(description: "loading")
        let expectFailure = expectation(description: "Received elements")
        store
            .statePublisher
            .sink { state in
                switch state.request {
                case .initial:
                    expectInitialState.fulfill()
                case .loading:
                    expectLoadingState.fulfill()
                case .failed:
                    expectFailure.fulfill()
                default: XCTFail()
                }
            }
            .store(in: &cancellables)
        store.dispatch(.request(.all))
        controller.requestPublisher.send(completion: .failure(NSError()))
        wait(for: [expectInitialState, expectLoadingState, expectFailure], timeout: 1, enforceOrder: true)
    }
    
    func testRequestElementsWithCollectionDifference() {
        let controller = Controller()
        let store = makeStore(with: controller)
        
        let expectInitialState = expectation(description: "Initial")
        let expectLoadingState = expectation(description: "loading")
        let expectElements = expectation(description: "Received elements")
        expectElements.expectedFulfillmentCount = 2
        
        let initialSongs = [Song(name: "Life is Beautiful"), Song(name: "Close Friends")]
        let finalSongs = [Song(name: "Close Friends"), Song.blueWorlds]
        let difference = finalSongs.difference(from: initialSongs)
        
        store
            .statePublisher
            .sink { state in
                switch state.request {
                case .initial:
                    expectInitialState.fulfill()
                case .loading:
                    expectLoadingState.fulfill()
                case .received(let elements):
                    XCTAssertTrue(elements == initialSongs || elements == [Song(name: "Close Friends"), Song.blueWorlds])
                    expectElements.fulfill()
                default: XCTFail()
                }
            }
            .store(in: &cancellables)
        store.dispatch(.request(.all))
        
        controller.requestPublisher.send(.elements(initialSongs))
        controller.requestPublisher.send(.difference(difference))
        wait(for: [expectInitialState, expectLoadingState, expectElements], timeout: 1, enforceOrder: true)
    }
    
    func testRequestElementsWithCollectionDifferenceInInitialState() {
        let controller = Controller()
        let store = makeStore(with: controller)
        
        let expectInitialState = expectation(description: "Initial")
        let expectLoadingState = expectation(description: "loading")
        let expectElements = expectation(description: "Received elements")
        
        let initialSongs = [Song(name: "Life is Beautiful"), Song(name: "Close Friends")]
        let finalSongs = [Song(name: "Close Friends"), Song.blueWorlds]
        let difference = finalSongs.difference(from: initialSongs)
        
        store
            .statePublisher
            .sink { state in
                switch state.request {
                case .initial:
                    expectInitialState.fulfill()
                case .loading:
                    expectLoadingState.fulfill()
                case .received(let elements):
                    XCTAssertEqual(elements.count, 1)
                    XCTAssertEqual(
                        elements.compactMap({ song in
                            guard song.name == Song.blueWorlds.name else {
                                return nil
                            }
                            return song
                        }),
                        [Song.blueWorlds]
                    )
                    expectElements.fulfill()
                default: XCTFail()
                }
            }
            .store(in: &cancellables)
        store.dispatch(.request(.all))
        
        controller.requestPublisher.send(.difference(difference))
        wait(for: [expectInitialState, expectLoadingState, expectElements], timeout: 1, enforceOrder: true)
    }
}

struct Controller: PersistenceController {
    private let failingError: NSError?
    let requestPublisher: PassthroughSubject<PersistenceFetchResult<Song>, NSError>
    
    init(error: NSError? = nil) {
        self.failingError = error
        self.requestPublisher = .init()
    }
    
    private func operationPublisher() -> AnyPublisher<Void, NSError> {
        if let failingError = failingError {
            return Fail(outputType: Void.self, failure: failingError)
                .eraseToAnyPublisher()
        } else {
            return Just(())
                .setFailureType(to: NSError.self)
                .eraseToAnyPublisher()
        }
    }
    
    func savePublisher(for element: Song) -> AnyPublisher<Void, NSError> {
        operationPublisher()
    }
    
    func deletePublisher(for element: Song) -> AnyPublisher<Void, NSError> {
        operationPublisher()
    }
    
    func requestPublisher(for request: SongRequest) -> AnyPublisher<PersistenceFetchResult<Song>, NSError> {
        requestPublisher
            .eraseToAnyPublisher()
    }
}

struct Song: Hashable {
    let name: String
    
    static let blueWorlds = Song(name: "Blue Worlds")
}

enum SongRequest {
    case all
}
