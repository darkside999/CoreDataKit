//
//  StorageContext.swift
//  CheckScan
//
//  Created by Indir Amerkhanov on 19.12.2019.
//  Copyright © 2019 Warefly. All rights reserved.
//

import CoreData

public protocol Storable {
    func setupDefaultValues()
}

protocol StorageContext {
    // MARK: - CRUD One object
    
    func create<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<DomainEntity>

    func save<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<Bool>

    func delete<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<Bool>

    // MARK: - CRUD Many objects
    
    func fetch<DomainEntity: Mappable>(
        _ model: DomainEntity.Type,
        predicate: NSPredicate?,
        sorted: Sorted?
    ) -> Finalizer<[DomainEntity]>
    
    func create<DomainEntity: Mappable>(objects: [DomainEntity]) -> Finalizer<[DomainEntity]>
    
    func save<DomainEntity: Mappable>(objects: [DomainEntity]) -> Finalizer<Bool>
    
    func deleteAll<DomainEntity: Mappable>(_ model: DomainEntity.Type) -> Finalizer<Bool>
}

public struct Sorted {
    let key: String
    let ascending: Bool
    
    public init(key: String, ascending: Bool) {
        self.key = key
        self.ascending = ascending
    }
}

public enum StorageContextError: Error {
    case unableCreateEntity
    case noManagedObject
    case saveError
}


