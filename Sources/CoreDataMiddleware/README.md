#  CoreDataMiddleware

## Getting Started

### Prerequisites

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
    For example, the counterpart for `ManagedSong` could be something like:
    ```swift
    struct Song: CoreDataPersistable {
        var title: String?

        // Required by CoreDataPersistable
        let managedObjectID: NSManagedObjectID?

        init(title: String?) {
            self.title = title
            self.managedObjectID = nil
        }

        // Required by CoreDataPersistable
        init(_ persistableObject: ManagedSong) throws {
            self.title = persistableObject.title
            self.managedObjectID = persistableObject.objectID
        }

        // Required by CoreDataPersistable
        func update(_ managedObject: ManagedSong) throws -> ManagedSong {
            if managedObject.title != title {
                managedObject.title = title
            }
            return managedObject
        }

        // Required by CoreDataPersistable
        static var managedObjectEntityName: String = "Song"
    }
    ```
- Lastly, every `CoreDataPersistable` conforming object must have a matching object conforming to `CoreDataRequest`.
    ```swift
    enum SongRequest: CoreDataRequest {
        case all
        case allWithTitle(String)

        // Required by CoreDataRequest
        typealias Element = Song
        
        // Required by CoreDataRequest
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
        
        // Required by CoreDataRequest
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
let controller = CoreDataController<SongRequest>(container)
let middleware = controller.makeMiddleware()
```

**Note**: If you have more than one entity, every entity-controller (like: `CoreDataController<SongRequest>`) must reference the same `CoreDataContainer`: 

```swift
let container = CoreDataContainer(NSPersistentContainer(name: "MusicDB"))

let albumController = CoreDataController<AlbumRequest>(container)
let songController = CoreDataController<SongRequest>(container)

let songMiddleware = songController.makeMiddleware()
let albumMiddleware = albumController.makeMiddleware()
```

## Note regarding `CoreDataContainer`
The implementation of `CoreDataContainer` does not entirely reflect the idea behind Redux and SwiftRex, since itself holds the loading state of the container and not the `AppState`. The reason why I chose the `CoreDataContainer` and not implemented a loading middleware is, that my main goal was to eliminate the need to dispatch a loading action. Every persistence action requires a loaded store and therefore a loading action seemed redundant.

### Other dismissed solutions

- Create one middleware with the only reference to the `NSPersistentContainer`, which receives a closure as an 
    action with the container as input parameter (TODO: Add an example).
