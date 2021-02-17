//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import Foundation
import CoreData
import Combine
import PersistenceMiddleware

private class ManagedObjectSubscription<S, P>: NSObject, Subscription, NSFetchedResultsControllerDelegate
where S: Subscriber, P: CoreDataPersistable, S.Input == PersistenceFetchResult<P>, S.Failure == CoreDataError {

    var subscriber: S?
    var resultController: NSFetchedResultsController<P.PersistableObject>?
    
    init(
        subscriber: S,
        fetchRequest: NSFetchRequest<P.PersistableObject>,
        context: NSManagedObjectContext,
        sectionNameKeyPath: String?,
        cacheName: String?
    ) {
        self.subscriber = subscriber
        self.resultController = NSFetchedResultsController<P.PersistableObject>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: cacheName
        )
        
        super.init()
        resultController?.delegate = self
    }
    
    func request(_ demand: Subscribers.Demand) {
        performFetch()
    }
    
    func cancel() {
        subscriber = nil
        resultController?.delegate = nil
        resultController = nil
    }
    
    func element(with objectID: NSManagedObjectID) -> Result<P, CoreDataError> {
        guard let managedObject = resultController?
                .managedObjectContext
                .object(with: objectID) as? P.PersistableObject else {
            return .failure(.unexpectedType(objectID: objectID))
        }
        return Result { try P(managedObject) }
            .mapError { .persistableError($0) }
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith diff: CollectionDifference<NSManagedObjectID>
    ) {
        let differenceResult = diff.resultMapChangeElement { element(with: $0) }
        switch differenceResult {
        case .failure(let error):
            subscriber?.receive(completion: .failure(error))
        case .success(let difference):
            _ = subscriber?.receive(.difference(difference))
        }
    }

    func performFetch() {
        guard let controller = resultController else { return }
        do {
            try controller.performFetch()
            
            if let result = controller.fetchedObjects {
                switch result.resultMap({ managedObject in Result { try P(managedObject) } }) {
                case .failure(let error):
                    _ = self.subscriber?.receive(completion: .failure(.persistableError(error)))
                case .success(let elements):
                    _ = self.subscriber?.receive(PersistenceFetchResult<P>.elements(elements))
                }
            }
        } catch {
            subscriber?.receive(completion: .failure(.requestError(error as NSError)))
        }
    }
}

struct CoreDataPersistablePublisher<P>: Publisher where P: CoreDataPersistable {
    public typealias Output = PersistenceFetchResult<P>
    public typealias Failure = CoreDataError
    
    private let context: NSManagedObjectContext
    private let fetchRequest: NSFetchRequest<P.PersistableObject>
    private let sectionNameKeyPath: String?
    private let cacheName: String?
    
    init(
        fetchRequest: NSFetchRequest<P.PersistableObject>,
        sortDescriptors: [NSSortDescriptor],
        context: NSManagedObjectContext,
        sectionNameKeyPath: String?,
        cacheName: String?
    ) {
        self.fetchRequest = fetchRequest
        self.fetchRequest.sortDescriptors = sortDescriptors
        self.context = context
        self.sectionNameKeyPath = sectionNameKeyPath
        self.cacheName = cacheName
    }
    
    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = ManagedObjectSubscription(
            subscriber: subscriber,
            fetchRequest: fetchRequest,
            context: context,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: cacheName
        )
        subscriber.receive(subscription: subscription)
    }
}
