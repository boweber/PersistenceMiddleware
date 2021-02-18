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
    case all
    case withName(String)
    
    var fetchRequest: NSFetchRequest<ManagedSong> {
        let request: NSFetchRequest<ManagedSong> = ManagedSong.fetchRequest()
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

