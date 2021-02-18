//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import Combine

public protocol PersistenceController {
    associatedtype PersistenceError: Error
    associatedtype Element
    associatedtype Request

    typealias Action = PersistenceAction<Element, PersistenceError, Request>
    typealias State = PersistenceState<Element, PersistenceError, Request>
    
    func savePublisher(for element: Element) -> AnyPublisher<Void, PersistenceError>
    func deletePublisher(for element: Element) -> AnyPublisher<Void, PersistenceError>
    func requestPublisher(for request: Request) -> AnyPublisher<PersistenceFetchResult<Element>, PersistenceError>
}
