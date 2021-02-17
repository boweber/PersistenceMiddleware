//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import Foundation

public struct PersistenceState<Element, PersistenceError, Request> where PersistenceError: Error {
    public var request: RequestState
    public var persist: ProcessState
    public var delete: ProcessState
    
    public enum RequestState {
        case initial
        case loading
        case failed(error: PersistenceError, request: Request)
        case received([Element])
        case canceled
    }

    public enum ProcessState {
        case initial
        case processing
        case failed(error: PersistenceError, element: Element)
        case succeeded
    }
}

extension PersistenceState {
    public static var initial: PersistenceState {
        PersistenceState(request: .initial, persist: .initial, delete: .initial)
    }
}
