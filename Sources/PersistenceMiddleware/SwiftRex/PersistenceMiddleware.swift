//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

import Combine
import SwiftRex
import CombineRex

extension PersistenceController {
    
    private func processPublisher(_ isPersist: Bool, for element: Element) -> AnyPublisher<Void, PersistenceError> {
        isPersist ? savePublisher(for: element) : deletePublisher(for: element)
    }
    
    // The middleware is only available through this function to eliminate the amount of generics to specify, which would be required otherwise.
    
    public func makeMiddleware() -> AnyMiddleware<Action, Action, State> {
        EffectMiddleware<Action, Action, State, Self>
            .onAction { incomingAction, dispatcher, _ in
                if let element = incomingAction.elementToProcess {
                    let isPersist = incomingAction.isPersistAction
                    return Effect { context in
                        context
                            .dependencies
                            .processPublisher(isPersist, for: element)
                            .map { DispatchedAction(.succeedProcess(isPersist), dispatcher: dispatcher) }
                            .catch { Just(DispatchedAction(.failProcess(isPersist, error: $0, element: element), dispatcher: dispatcher)) }
                            .eraseToAnyPublisher()
                    }
                } else if case .request(let requestAction) = incomingAction.wrappedAction {
                    switch requestAction {
                    case .request(let request):
                        return Effect(token: 1) { context in
                            context.dependencies
                                .requestPublisher(for: request)
                                .map { DispatchedAction(.receive($0), dispatcher: dispatcher) }
                                .catch { Just(DispatchedAction(.failRequest($0, request: request), dispatcher: dispatcher)) }
                                .eraseToAnyPublisher()
                        }
                    case .cancel:
                        return .toCancel(1)
                    default:
                        return .doNothing
                    }
                }
                return .doNothing
            }
            .inject(self)
            .eraseToAnyMiddleware()
    }
}
