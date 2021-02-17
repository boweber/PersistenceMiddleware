//
//  File.swift
//  
//
//  Created by Bo Weber on 15.02.21.
//

import Foundation
import PersistenceMiddleware
import CoreDataMiddleware

struct AppState {
    var artist: PersistenceState<SongArtist, CoreDataError, SongArtistRequest> = .initial
    var title: PersistenceState<SongTitle, CoreDataError, SongTitleRequest> = .initial
}
