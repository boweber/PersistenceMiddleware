//
//  File.swift
//  
//
//  Created by Bo Weber on 15.02.21.
//

import Foundation
import CoreData
import CoreDataMiddleware

struct SongTitle: CoreDataPersistable, Equatable {
    static func == (lhs: SongTitle, rhs: SongTitle) -> Bool {
        lhs.title == rhs.title
    }
    
    var title: String?
    let managedObjectID: NSManagedObjectID?
    var updateError: CoreDataError?
    
    init(title: String?, managedObjectID: NSManagedObjectID? = nil, updateError: CoreDataError? = nil) {
        self.title = title
        self.managedObjectID = managedObjectID
        self.updateError = updateError
    }
    
    init(_ persistableObject: ManagedSong) throws {
        try Self.failingError.map { throw $0 }
        self.init(
            title: persistableObject.title,
            managedObjectID: persistableObject.objectID,
            updateError: nil
        )
    }

    func update(_ managedObject: ManagedSong) throws -> ManagedSong {
        try updateError.map { throw $0 }
        managedObject.title = title
        return managedObject
    }
    
    static var failingError: CoreDataError? = nil
    static var managedObjectEntityName: String = "Song"
}
