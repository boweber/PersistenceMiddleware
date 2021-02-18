//
//  File.swift
//  
//
//  Created by Bo Weber on 15.02.21.
//

import Foundation
import CoreData
import CoreDataMiddleware

enum SongTitleRequest: CoreDataRequest {
    case all
    case withTitle(String)
    
    var fetchRequest: NSFetchRequest<ManagedSong> {
        let request: NSFetchRequest<ManagedSong> = ManagedSong.fetchRequest()
        switch self {
        case .withTitle(let title):
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
