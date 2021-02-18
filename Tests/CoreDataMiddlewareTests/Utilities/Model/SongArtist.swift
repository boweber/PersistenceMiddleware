//
//  File.swift
//  
//
//  Created by Bo Weber on 12.02.21.
//

import Foundation
import CoreData
import CoreDataMiddleware

struct SongArtist: CoreDataPersistable, Equatable {
    typealias Request = SongArtistRequest
    static func == (lhs: SongArtist, rhs: SongArtist) -> Bool {
        lhs.artistName == rhs.artistName
    }
    
    var artistName: String?
    let managedObjectID: NSManagedObjectID?
    var updateError: CoreDataError?
    
    init(artistName: String?, managedObjectID: NSManagedObjectID? = nil, updateError: CoreDataError? = nil) {
        self.artistName = artistName
        self.managedObjectID = managedObjectID
        self.updateError = updateError
    }
    
    init(_ persistableObject: ManagedSong) throws {
        try Self.failingError.map { throw $0 }
        self.init(
            artistName: persistableObject.artist,
            managedObjectID: persistableObject.objectID,
            updateError: nil
        )
    }

    func update(_ managedObject: ManagedSong) throws -> ManagedSong {
        try updateError.map { throw $0 }
        managedObject.artist = artistName
        return managedObject
    }
    static var failingError: CoreDataError? = nil
    static var managedObjectEntityName: String = "Song"
}
