//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import CoreData

public protocol CoreDataPersistable {
    associatedtype PersistableObject
    associatedtype Request: CoreDataRequest where Request.ManagedObject == PersistableObject
    
    var managedObjectID: NSManagedObjectID? { get }
    init(_ persistableObject: PersistableObject) throws
    func update(_ managedObject: PersistableObject) throws -> PersistableObject
    
    static var managedObjectEntityName: String { get }
}
