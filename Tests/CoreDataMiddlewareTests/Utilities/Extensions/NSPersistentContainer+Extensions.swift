//
//  File.swift
//  
//
//  Created by Bo Weber on 06.02.21.
//

import Foundation
import CoreData

extension NSPersistentContainer {
    static var testContainer: NSPersistentContainer? {
        guard let url = Bundle.module.url(forResource: "Music", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            return nil
        }
        let container = NSPersistentContainer(name: "Music", managedObjectModel: model)
        container
            .persistentStoreDescriptions
            .forEach { $0.setupAsInMemoryStore() }
        return container
    }
}

private extension NSPersistentStoreDescription {
    func setupAsInMemoryStore() {
        url = URL(fileURLWithPath: "/dev/null")
    }
}
