//
//  File.swift
//  
//
//  Created by Bo Weber on 15.02.21.
//

import Foundation

extension NSError {
    static func testError(domain: String = "Test", code: Int = 1) -> NSError {
        NSError(domain: "Test", code: 1, userInfo: [:])
    }
}
