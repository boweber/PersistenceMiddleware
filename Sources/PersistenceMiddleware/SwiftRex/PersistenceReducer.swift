//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import Foundation
import SwiftRex

extension PersistenceController {
    
    private static var processReducer: Reducer<Action.ProcessAction, State.ProcessState> {
        .reduce { action, state in
            switch action {
            case .process:
                state = .processing
            case .succeed:
                state = .succeeded
            case let .fail(error: error, element: element):
                state = .failed(error: error, element: element)
            }
        }
    }
    
    public static func makeReducer() -> Reducer<Action, State> {
        .reduce { action, state in
            switch action.wrappedAction {
            case .delete(let deleteAction):
                processReducer.reduce(deleteAction, &state.delete)
            case .persist(let persistAction):
                processReducer.reduce(persistAction, &state.persist)
            case .request(let requestAction):

                switch requestAction {
                case .request:
                    state.request = .loading
                case .receive(let fetchResult):

                    switch fetchResult {
                    case .elements(let elements):
                        state.request = .received(elements)
                    case .difference(let difference):
                        
                        // TODO: If difference is not compatible -> fail?!
                        
                        if case .received(let elements) = state.request {
                            state.request = .received(difference.map({ (elements.applying($0) ?? []) }) ?? [])
                        } else {
                            
                            // This might be not necessary and furthermore missleading
                            
                            let elements: [Element]? = difference?
                                .insertions
                                .compactMap { change in
                                    guard case .insert(offset: _, element: let element, associatedWith: _) = change else { return nil }
                                    return element
                                }
                            state.request = .received(elements ?? [])
                        }

                    }

                case .cancel:
                    state.request = .canceled
                case let .fail(error: error, request: request):
                    state.request = .failed(error: error, request: request)
                }
            }
        }
    }
}
