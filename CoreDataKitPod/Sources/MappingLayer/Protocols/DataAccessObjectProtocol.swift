//
//  DataAccessObjectProtocol.swift
//  CoreDataKit
//
//  Created by Indir Amerkhanov on 18.03.2020.
//

import Foundation

public protocol DataAccessObjectProtocol {
    func save<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<DomainEntity>
    
    func save<DomainEntity: Mappable>(objects: [DomainEntity]) -> Finalizer<[DomainEntity]>
    
    func update<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<Bool>

    func delete<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<Bool>

    func deleteAll<DomainEntity: Mappable>(_ model: DomainEntity.Type) -> Finalizer<Bool>

    func fetch<DomainEntity: Mappable>(_ model: DomainEntity.Type, predicate: NSPredicate?, sorted: Sorted?) -> Finalizer<[DomainEntity]>
}
