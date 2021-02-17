//
//  File.swift
//  
//
//  Created by Bo Weber on 14.02.21.
//

import Foundation
import CoreData
import Combine

extension NSPersistentContainer {
    func loadPersistentStores() -> Future<Void, Error> {
        Future { promise in
            self.loadPersistentStores { _, error in
                promise(error.map { .failure($0) } ?? .success(()))
            }
        }
    }
}
