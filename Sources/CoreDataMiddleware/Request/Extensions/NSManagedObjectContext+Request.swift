//
//  File.swift
//  
//
//  Created by Bo Weber on 15.02.21.
//

import CoreData
import Combine
import PersistenceMiddleware

extension NSManagedObjectContext {
    func request<Element>(
        _ request: Element.Request
    ) -> AnyPublisher<PersistenceFetchResult<Element>, CoreDataError> where Element: CoreDataPersistable {
        CoreDataPersistablePublisher(
            fetchRequest: request.fetchRequest,
            sortDescriptors: request.sortDescriptors,
            context: self,
            sectionNameKeyPath: request.sectionNameKeyPath,
            cacheName: request.cacheName
        )
        .eraseToAnyPublisher()
    }
}
