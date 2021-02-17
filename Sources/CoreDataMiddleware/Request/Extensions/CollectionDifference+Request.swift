//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import Foundation

extension CollectionDifference {
    func resultMapChangeElement<T, Failure>(
        _ transform: (ChangeElement) -> Result<T, Failure>
    ) -> Result<CollectionDifference<T>?, Failure> where Failure: Error {
        var result: [CollectionDifference<T>.Change] = []
        
        for change in self {
            switch change {
            case let .insert(offset: offset, element: element, associatedWith: associatedIndex):
                switch transform(element) {
                case .failure(let error):
                    return .failure(error)
                case .success(let transformedElement):
                    result.append(.insert(offset: offset, element: transformedElement, associatedWith: associatedIndex))
                }
            case let .remove(offset: offset, element: element, associatedWith: associatedIndex):
                switch transform(element) {
                case .failure(let error):
                    return .failure(error)
                case .success(let transformedElement):
                    result.append(.remove(offset: offset, element: transformedElement, associatedWith: associatedIndex))
                }
            }
        }
        return .success(CollectionDifference<T>(result))
    }
}
