//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import CoreData

extension NSEntityDescription {
    static func description(forEntityName name: String, in context: NSManagedObjectContext) -> Result<NSEntityDescription, CoreDataError> {
        entity(forEntityName: name, in: context).map { .success($0) } ?? .failure(.missingEntityDescription(entityName: name))
    }
}
