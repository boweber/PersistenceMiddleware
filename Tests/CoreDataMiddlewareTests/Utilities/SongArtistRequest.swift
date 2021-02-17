//
//  File.swift
//  
//
//  Created by Bo Weber on 12.02.21.
//

import Foundation
import CoreData
import CoreDataMiddleware

enum SongArtistRequest: CoreDataRequest {
    typealias Element = SongArtist
    
    case all
    case withName(String)
    
    var fetchRequest: NSFetchRequest<SongArtist.PersistableObject> {
        let request: NSFetchRequest<SongArtist.PersistableObject> = ManagedSong.fetchRequest()
        switch self {
        case .withName(let name):
            request.predicate = NSPredicate(format: "%K == %@", "artist", name)
        default:
            break
        }
        return request
    }
    
    var sortDescriptors: [NSSortDescriptor] {
        [
            NSSortDescriptor(keyPath: \ManagedSong.artist, ascending: true)
        ]
    }
}

