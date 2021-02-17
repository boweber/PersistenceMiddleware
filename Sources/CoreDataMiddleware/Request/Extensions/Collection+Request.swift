//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import Foundation

extension Collection {
    func resultMap<Success, Failure>(
        _ transform: (Element) -> Result<Success, Failure>
    ) -> Result<[Success], Failure> {
        var result: [Success] = []
        for element in self {
            switch transform(element) {
            case .failure(let error): return .failure(error)
            case .success(let success):
                result.append(success)
            }
        }
        return .success(result)
    }
}
