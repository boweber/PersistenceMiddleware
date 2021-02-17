//
//  File.swift
//  
//
//  Created by Bo Weber on 15.02.21.
//

import Foundation
import Combine

extension Fail {
    static func testFailure(outputType: Output.Type, error: Error = NSError.testError()) -> AnyPublisher<Output, Failure> where Failure == Error {
        Fail(outputType: Output.self, failure: error)
            .eraseToAnyPublisher()
    }
}
