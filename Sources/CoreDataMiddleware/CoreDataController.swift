//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import CoreData
import PersistenceMiddleware
import Combine

public struct CoreDataController<Request>: PersistenceController where Request: CoreDataRequest {

    private let savePublisher: (NSPersistentContainer, Request.Element) -> AnyPublisher<Void, CoreDataError>
    private let deletePublisher: (NSPersistentContainer, Request.Element) -> AnyPublisher<Void, CoreDataError>
    private let requestPublisher: (NSPersistentContainer, Request) -> AnyPublisher<PersistenceFetchResult<Request.Element>, CoreDataError>
    private let containerManager: CoreDataContainer
    
    // TODO: Make the initilizer with custom publishers internal ?!

    public init(
        _ container: CoreDataContainer,
        savePublisher: ((NSPersistentContainer, Request.Element) -> AnyPublisher<Void, CoreDataError>)? = nil,
        deletePublisher: ((NSPersistentContainer, Request.Element) -> AnyPublisher<Void, CoreDataError>)? = nil,
        requestPublisher: ((NSPersistentContainer, Request) -> AnyPublisher<PersistenceFetchResult<Request.Element>, CoreDataError>)? = nil
    ) {
        self.containerManager = container
        self.savePublisher = savePublisher ?? { container, element in
            Future { promise in
                container
                    .performBackgroundTask { context in
                        let result: Result<Request.Element.PersistableObject, CoreDataError>
                        if let savedObject = context.retrieve(element) {
                            result = Result { try element.update(savedObject) }.mapError { .persistableError($0) }
                        } else {
                            result = context.makeManagedObject(basedOn: element)
                        }
                        return promise(result.flatMap { _ in context.saveChanges() })
                    }
            }.eraseToAnyPublisher()
        }

        self.deletePublisher = deletePublisher ?? { container, element in
            Future { promise in
                container
                    .performBackgroundTask { context in
                        context.delete(element)
                        return promise(context.saveChanges())
                    }
            }
            .eraseToAnyPublisher()
        }

        self.requestPublisher = requestPublisher ?? { container, request in
            container
                .viewContext
                .request(request)
        }
    }
    
    private func flatMapContainerPublisher<O>(
        with publisher: @escaping (NSPersistentContainer) -> AnyPublisher<O, CoreDataError>
    ) -> AnyPublisher<O, CoreDataError> {
        containerManager
            .containerPublisher()
            .mapError { .containerError($0) }
            .flatMap { publisher($0) }
            .eraseToAnyPublisher()
    }

    public func savePublisher(for element: Request.Element) -> AnyPublisher<Void, CoreDataError> {
        flatMapContainerPublisher { savePublisher($0, element) }
    }
    
    public func deletePublisher(for element: Request.Element) -> AnyPublisher<Void, CoreDataError> {
        flatMapContainerPublisher { deletePublisher($0, element) }
    }
    
    public func requestPublisher(for request: Request) -> AnyPublisher<PersistenceFetchResult<Request.Element>, CoreDataError> {
        flatMapContainerPublisher { requestPublisher($0, request) }
    }
}

