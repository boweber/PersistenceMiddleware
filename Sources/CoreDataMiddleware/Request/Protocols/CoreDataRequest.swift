//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import CoreData
import PersistenceMiddleware

public protocol CoreDataRequest {
    associatedtype Element: CoreDataPersistable
    
    var fetchRequest: NSFetchRequest<Element.PersistableObject> { get }
    var sortDescriptors: [NSSortDescriptor] { get }
    var sectionNameKeyPath: String? { get }
    var cacheName: String? { get }
}

public extension CoreDataRequest {
    var sectionNameKeyPath: String? { nil }
    var cacheName: String? { nil }
}
