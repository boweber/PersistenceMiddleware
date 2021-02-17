//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import CoreData

extension NSManagedObjectContext {
    func saveChanges() -> Result<Void, CoreDataError> {
        Result { if hasChanges { try save() } }
            .mapError { .savingError($0) }
    }
    
    func retrieve<P>(_ persistable: P) -> P.PersistableObject? where P: CoreDataPersistable {
        guard let objectID = persistable.managedObjectID else { return nil }
        return object(with: objectID) as? P.PersistableObject
    }
    
    func delete<P>(_ persistable: P) where P: CoreDataPersistable {
        guard let managedObject = retrieve(persistable) else { return }
        delete(managedObject)
    }
    
    func makeManagedObject<P>(
        basedOn persistable: P
    ) -> Result<P.PersistableObject, CoreDataError> where P: CoreDataPersistable {
        NSEntityDescription
            .description(forEntityName: P.managedObjectEntityName, in: self)
            .map { P.PersistableObject(entity: $0, insertInto: self) }
            .flatMap { managedObject in
                Result {
                    try persistable
                        .update(managedObject)
                }
                .mapError { .persistableError($0) }
            }
    }
}
