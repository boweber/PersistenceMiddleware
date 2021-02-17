//
//  File.swift
//  
//
//  Created by Bo Weber on 15.02.21.
//

import Foundation
import PersistenceMiddleware
import CoreDataMiddleware

enum AppAction {
    case artist(CoreDataController<SongArtistRequest>.Action)
    case title(PersistenceAction<SongTitle, CoreDataError, SongTitleRequest>)
    
    
    var artist: PersistenceAction<SongArtist, CoreDataError, SongArtistRequest>? {
        get {
            guard case let .artist(value) = self else { return nil }
            return value
        }
        set {
            guard case .artist = self, let newValue = newValue else { return }
            self = .artist(newValue)
        }
    }
    
    var title: PersistenceAction<SongTitle, CoreDataError, SongTitleRequest>? {
        get {
            guard case let .title(value) = self else { return nil }
            return value
        }
        set {
            guard case .title = self, let newValue = newValue else { return }
            self = .title(newValue)
        }
    }
    
}

