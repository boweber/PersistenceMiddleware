//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import CoreData

public enum CoreDataError: Error {
    /// This can be a loading store error or a Container configuration error
    case containerError(Error)
    case requestError(NSError)
    case savingError(Error)
    case unexpectedType(objectID: NSManagedObjectID)
    case unknownType(expectedType: String)
    case missingEntityDescription(entityName: String)
    case missingContext(NSManagedObject)
    case persistableError(Error)
}

