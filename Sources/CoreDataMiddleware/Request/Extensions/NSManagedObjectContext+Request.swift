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
    func request<Request>(
        _ request: Request
    ) -> AnyPublisher<PersistenceFetchResult<Request.Element>, CoreDataError> where Request: CoreDataRequest {
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
