//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import CoreData

public protocol CoreDataPersistable {
    associatedtype PersistableObject: NSManagedObject
    
    var managedObjectID: NSManagedObjectID? { get }
    init(_ persistableObject: PersistableObject) throws
    func update(_ managedObject: PersistableObject) throws -> PersistableObject
    
    static var managedObjectEntityName: String { get }
}
