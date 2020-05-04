//
//  Finalizer.swift
//  CoreDataKit
//
//  Created by Indir Amerkhanov on 18.03.2020.
//

import Foundation

public final class Finalizer<T> {
    public final class Resolver {
        public var state: Result? {
            didSet {
                guard stateDidSet == false else {
                    print("Finalizer error: Repeated set state not permitted!")
                    return
                }
                
                stateDidSet = true
                
                switch state {
                case let .fulfilled(data):
                    doneCompletion(data)
                case let .rejected(error):
                    print(error)
                    catchCompletion(error)
                default:
                    break
                }
            }
        }
        
        private var stateDidSet: Bool = false
        
        var catchCompletion: (Error) -> Void = { _ in }
        var doneCompletion: (T) -> Void = { _ in }
    }
    
    public typealias ResultCompletion = (Resolver) -> Void
    
    public enum Result {
        case fulfilled(T)
        case rejected(Error)
    }
    
    let resolver: Resolver = Resolver()
    var task: ResultCompletion?

    private var executed: Bool = false
    
    public init(_ task: @escaping ResultCompletion) {
        self.task = task
    }
    
    public func done(completionHandler: @escaping (T) -> Void) -> Self {
        guard executed == false else { return self }
        
        executed = true
        
        resolver.doneCompletion = { data in
            DispatchQueue.main.async {
                completionHandler(data)
            }
        }
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.1) {
            self.task?(self.resolver)
            self.task = nil
        }
        
        return self
    }
    
    public func `catch`(errorHandler: @escaping (Error) -> Void) {
        resolver.catchCompletion = { error in
            DispatchQueue.main.async {
                errorHandler(error)
            }
        }
        
        runTaskIfNeeded()
    }
    
    public func asVoid() {
        runTaskIfNeeded()
    }
    
    private func runTaskIfNeeded() {
        guard executed == false else { return }
        
        executed = true
        
        task?(self.resolver)
        task = nil
    }
}
