#  CoreDataMiddleware

## Getting Started

### Prerequisites

- You need to be familiar with [PersistenceMiddleware](../PersistenceMiddleware/README.md).
- Just like in every *Core Data* related project, you need a `NSManagedObjectModel`, containing details about every entity. 
    For example, a model with the name "MusicDB" has two entities *Song* and *Album* with an associated `NSManagedObject` for each of them. The *Song* entity 
    has for simplicity reasons just one attribute *title*:
    ```swift 
    @objc(ManagedSong)
    class ManagedSong: NSMangedObject {
        @NSManaged var title: String?
    }
    ```
- Every entity (that should be handled by a persistence middleware) must have a value-object as a counterpart that conforms to the `CoreDataPersistable` protocol.
    ```swift
    public protocol CoreDataPersistable {
        associatedtype PersistableObject
        associatedtype Request: CoreDataRequest where Request.ManagedObject == PersistableObject
        
        var managedObjectID: NSManagedObjectID? { get }
        init(_ persistableObject: PersistableObject) throws
        func update(_ managedObject: PersistableObject) throws -> PersistableObject
        
        static var managedObjectEntityName: String { get }
    }
    ```
    For example, the counterpart for `ManagedSong` could be something like:
    ```swift
    struct Song: CoreDataPersistable {
        var title: String?
        let managedObjectID: NSManagedObjectID?

        init(title: String?) {
            self.title = title
            self.managedObjectID = nil
        }

        init(_ persistableObject: ManagedSong) throws {
            self.title = persistableObject.title
            self.managedObjectID = persistableObject.objectID
        }

        func update(_ managedObject: ManagedSong) throws -> ManagedSong {
            if managedObject.title != title {
                managedObject.title = title
            }
            return managedObject
        }

        static var managedObjectEntityName: String = "Song"
        typealias Request = SongRequest
    }
    ```
- Lastly, every `CoreDataPersistable` conforming object must have a matching object conforming to `CoreDataRequest`.
    ```swift
    enum SongRequest: CoreDataRequest {
        case all
        case allWithTitle(String)

        var fetchRequest: NSFetchRequest<ManagedSong> {
            let request: NSFetchRequest<ManagedSong> = ManagedSong.fetchRequest()
            switch self {
            case .allWithTitle(let title):
                request.predicate = NSPredicate(format: "%K == %@", "title", title)
            default:
                break
            }
            return request
        }
        
        var sortDescriptors: [NSSortDescriptor] {
            [
                NSSortDescriptor(keyPath: \ManagedSong.title, ascending: true)
            ]
        }
    }
    ```

### Creating the middleware

The `CoreDataController` (which conforms to `PersistenceController`) is initialized with an object of type `CoreDataContainer`, which 
is a wrapper for either a `NSPersistentContainer` or a `NSPersistentCloudKitContainer`.
```swift
let container = CoreDataContainer(NSPersistentContainer(name: "MusicDB"))
let controller = CoreDataController<Song>(container)
let middleware = controller.makeMiddleware()
```

**Note**: If you have more than one entity, every entity-controller (like: `CoreDataController<Song>`) must reference the same `CoreDataContainer`: 

```swift
let container = CoreDataContainer(NSPersistentContainer(name: "MusicDB"))

let albumController = CoreDataController<Album>(container)
let songController = CoreDataController<Song>(container)

let songMiddleware = songController.makeMiddleware()
let albumMiddleware = albumController.makeMiddleware()
```

## Note regarding `CoreDataContainer`
The implementation of `CoreDataContainer` does not entirely reflect the idea behind Redux and SwiftRex, since itself holds the loading state of the container and not the `AppState`. The reason why I chose the `CoreDataContainer` and not implemented a loading middleware is, that my main goal was to eliminate the need to dispatch a loading action. Every persistence action requires a loaded store and therefore a loading action seemed redundant. If you nonetheless want the loading state in your app state, this can be accomplished with an extension to the `PersistenceState`:
```swift

enum ContainerLoadingState {
    case initial
    case loading
    case loaded
    case failed(Error)
}

extension PersistenceState where PersistenceError == CoreDataError {
    var containerLoadingState: ContainerLoadingState {
        // TODO
    }
}
```

### Other dismissed solutions

- Create one middleware with the only reference to the `NSPersistentContainer`, which receives a closure as an 
    action with the container as input parameter (TODO: Add an example).
