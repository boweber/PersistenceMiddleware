//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import CoreData

public protocol CoreDataRequest {
    associatedtype ManagedObject: NSManagedObject
    
    var fetchRequest: NSFetchRequest<ManagedObject> { get }
    var sortDescriptors: [NSSortDescriptor] { get }
    var sectionNameKeyPath: String? { get }
    var cacheName: String? { get }
}

public extension CoreDataRequest {
    var sectionNameKeyPath: String? { nil }
    var cacheName: String? { nil }
}
