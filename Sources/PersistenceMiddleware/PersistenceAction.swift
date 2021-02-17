//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

public struct PersistenceAction<Element, PersistenceError, Request> where PersistenceError: Error {
    let wrappedAction: WrappedAction
    
    var elementToProcess: Element? {
        switch wrappedAction {
        case .delete(let action):
            if case .process(let element) = action {
                return element
            }
        case .persist(let action):
            if case .process(let element) = action {
                return element
            }
        case .request:
            return nil
        }
        return nil
    }
    
    var isPersistAction: Bool {
        guard case .persist = wrappedAction else {
            return false
        }
        return true
    }
    
    
    enum WrappedAction {
        case request(RequestAction)
        case persist(ProcessAction)
        case delete(ProcessAction)
    }
    
    enum RequestAction {
        case request(Request)
        case receive(PersistenceFetchResult<Element>)
        case cancel
        case fail(error: PersistenceError, request: Request)
    }

    enum ProcessAction {
        case process(Element)
        case succeed
        case fail(error: PersistenceError, element: Element)
    }
}

// MARK: - Internal

extension PersistenceAction {
    
    static func failProcess(
        _ isPersistProcess: Bool,
        error: PersistenceError,
        element: Element
    ) -> PersistenceAction {
        let process: ProcessAction = .fail(error: error, element: element)
        return PersistenceAction(wrappedAction: isPersistProcess ? .persist(process) : .delete(process))
    }
    
    static func succeedProcess(_ isPersistProcess: Bool) -> PersistenceAction {
        PersistenceAction(
            wrappedAction: isPersistProcess ? .persist(.succeed) : .delete(.succeed)
        )
    }

    static func failRequest(_ error: PersistenceError, request: Request) -> PersistenceAction {
        PersistenceAction(wrappedAction: .request(.fail(error: error, request: request)))
    }
    
    static func receive(_ result: PersistenceFetchResult<Element>) -> PersistenceAction {
        PersistenceAction(wrappedAction: .request(.receive(result)))
    }
}

// MARK: - Public

public extension PersistenceAction {
    static var cancelRequest: PersistenceAction {
        PersistenceAction(wrappedAction: .request(.cancel))
    }
    
    static func save(_ element: Element) -> PersistenceAction {
        PersistenceAction(wrappedAction: .persist(.process(element)))
    }
    
    static func delete(_ element: Element) -> PersistenceAction {
        PersistenceAction(wrappedAction: .delete(.process(element)))
    }
    
    static func request(_ request: Request) -> PersistenceAction {
        PersistenceAction(wrappedAction: .request(.request(request)))
    }
}
