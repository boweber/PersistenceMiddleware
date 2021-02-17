#  PersistenceMiddleware

## Getting Started

The persistence middleware package provides the following *SwiftRex* compatible components.
-   **Action**  
The `PersistenceAction<Element, PersistenceError, Request>` object is a generic action. `Element` is an object that can be saved, deleted, updated and requested by the middleware. If one of those 
actions fail, the error is represented by a `PersistenceError` object. A `Request` object contains details for a fetch request (e.g. a `NSFetchRequest`).
    ```swift
    public struct PersistenceAction<Element, PersistenceError, Request> where PersistenceError: Error {
        public static var cancelRequest: PersistenceAction
        public static func save(_ element: Element) -> PersistenceAction
        public static func delete(_ element: Element) -> PersistenceAction
        public static func request(_ request: Request) -> PersistenceAction
    }
    ```
-   **State**  
The state is represented by a `PersistenceState<Element, PersistenceError, Request>` object.
    ```swift
    public struct PersistenceState<Element, PersistenceError, Request> where PersistenceError: Error {
        public var request: RequestState
        public var persist: ProcessState
        public var delete: ProcessState

        public enum RequestState {
            case initial
            case loading
            case failed(error: PersistenceError, request: Request)
            case received([Element])
            case canceled
        }

        public enum ProcessState {
            case initial
            case processing
            case failed(error: PersistenceError, element: Element)
            case succeeded
        }
    }
    ```
- **Middleware**  
The middleware is only accessible through an object, which conforms to the `PersistenceController` protocol:
    ```swift
    public protocol PersistenceController {
        associatedtype PersistenceError: Error
        associatedtype Element
        associatedtype Request

        typealias Action = PersistenceAction<Element, PersistenceError, Request>
        typealias State = PersistenceState<Element, PersistenceError, Request>

        func savePublisher(for element: Element) -> AnyPublisher<Void, PersistenceError>
        func deletePublisher(for element: Element) -> AnyPublisher<Void, PersistenceError>
        func requestPublisher(for request: Request) -> AnyPublisher<PersistenceFetchResult<Element>, PersistenceError>
    }

    public extension PersistenceController {
        public func makeMiddleware() -> AnyMiddleware<Action, Action, State>
    }
    ```
    The `makeMiddleware()` function in `PersistenceController` should reduce the amount of generics to specify, which would be otherwise required. For Example, the `CoreDataController` (see: *CoreDataMiddleware*) just has one generic type to specify.
    ```swift
    let controller = CoreDataController<SongRequest>(NSPersistentContainer(name: "MusicDB"))
    let middleware = controller.makeMiddleware()
    ```
    which is much easier to read, compared to
    ```swift
    let controller = CoreDataController<SongRequest>(NSPersistentContainer(name: "MusicDB"))

    // Here: makeMiddleware<Request>(_ controller: CoreDataController<Request>) is globally accessible
    let middleware: AnyMiddleware<
                PersistenceAction<Song, SongError, SongRequest>,
                PersistenceAction<Song, SongError, SongRequest>,
                PersistenceState<Song, SongError, SongRequest>
            > = makeMiddleware(controller) 
    ```

- **Reducer**  
Just like the middleware, the reducer is bound to a `PersistenceController` type as a static variable:
    ```swift
    public extension PersistenceController {
        public static func makeReducer() -> Reducer<Action, State>
    }
    ```

## TODO

- Add actions to cancel the current save/delete process ?!
- Add action handling *move element from index to index* 
- Add multiple states for different requests ?!  
    This could be archived with a dictionary (e.g. `[Request.Token: RequestState]`) instead of just `RequestState` as the request parameter type. 
- Implement section support
- Implement cache support (reloading previously fetched elements)
- Implement error resolving functionality
- Add documentation.
