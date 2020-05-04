//
//  CoreDataStorageContext+StorageContext.swift
//  CoreDataTest
//
//  Created by Indir Amerkhanov on 19.03.2020.
//  Copyright © 2020 Indir Amerkhanov. All rights reserved.
//

import Foundation
import CoreData

extension CoreDataStorageContext: StorageContext {
    // MARK: - CUD One object
    
    func create<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<DomainEntity> {
        Finalizer<DomainEntity> { resolver in
            self.privateManagedContext.performBackgroundTask { privateManagedContext in
                guard let entity = self.createNSManagedObject(
                    DomainEntity.Persistance.self,
                    in: privateManagedContext
                ) else {
                    resolver.state = .rejected(StorageContextError.unableCreateEntity)
                    return
                }
                
                entity.setupDefaultValues()
                object.mapManagedObject(target: entity)
                
                do {
                    try privateManagedContext.saveIfNeeded()
                    
                } catch {
                    resolver.state = .rejected(error)
                    return
                }
                
                let privateObjectID = entity.objectID
                
                self.mainManagedContext.performAndWait {
                    do {
                        guard let mainEntity = self.mainManagedContext.insertedObjects.first(
                            where: { $0.objectID == privateObjectID }
                        ) else { return }
                        
                        try self.mainManagedContext.obtainPermanentIDs(
                            for: Array(self.mainManagedContext.insertedObjects)
                        )
                        
                        try self.mainManagedContext.saveIfNeeded()
                        
                        let mappedObject = try DomainEntity.mapFrom(mainEntity)
                        
                        print("CoreData: Created entity \(String(describing: DomainEntity.Persistance.self))")
                        
                        resolver.state = .fulfilled(mappedObject)
                    } catch {
                        resolver.state = .rejected(error)
                    }
                }
            }
        }
    }

    func save<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<Bool> {
        Finalizer<Bool> { resolver in
            self.privateManagedContext.performBackgroundTask { privateManagedContext in
                guard let managedObject = privateManagedContext.object(for: object) else {
                    resolver.state = .rejected(StorageContextError.noManagedObject)
                    return
                }
                
                object.mapManagedObject(target: managedObject)
            
                do {
                    try privateManagedContext.saveIfNeeded()
                } catch {
                    resolver.state = .rejected(error)
                    return
                }
                
                self.mainManagedContext.performAndWait {
                    do {
                        try self.mainManagedContext.saveIfNeeded()
                        
                        print("CoreData: Saved entity \(String(describing: DomainEntity.Persistance.self))")
                        
                        resolver.state = .fulfilled(true)
                    } catch {
                        resolver.state = .rejected(error)
                    }
                }
            }
        }
    }

    func delete<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<Bool> {
        Finalizer<Bool> { resolver in
            self.privateManagedContext.performBackgroundTask { privateManagedContext in
                guard let managedObject = privateManagedContext.object(for: object) else {
                    resolver.state = .rejected(StorageContextError.noManagedObject)
                    return
                }
        
                privateManagedContext.delete(managedObject)

                do {
                    try privateManagedContext.saveIfNeeded()
                } catch {
                    resolver.state = .rejected(error)
                    return
                }
                
                self.mainManagedContext.performAndWait {
                    do {
                        try self.mainManagedContext.saveIfNeeded()
                        
                        print("CoreData: Deleted entity \(String(describing: DomainEntity.Persistance.self))")
                        
                        resolver.state = .fulfilled(true)
                    } catch {
                        resolver.state = .rejected(error)
                    }
                }
            }
        }
    }
    
    // MARK: - CRUD Many objects

    func fetch<DomainEntity: Mappable>(
        _ model: DomainEntity.Type,
        predicate: NSPredicate?,
        sorted: Sorted?
    ) -> Finalizer<[DomainEntity]> {
        Finalizer<[DomainEntity]> { resolver in
            self.mainManagedContext.performAndWait {
                let fetchRequest = DomainEntity.Persistance.getFetchRequest()
                fetchRequest.predicate = predicate
                
                if let sorted = sorted {
                    fetchRequest.sortDescriptors = [.init(key: sorted.key, ascending: sorted.ascending)]
                }
                
                do {
                    let result = try self.mainManagedContext.fetch(fetchRequest)
                    let mappedResult = try result.map { try DomainEntity.mapFrom($0) }
                    
                    print("CoreData: Fetched entity \(String(describing: DomainEntity.Persistance.self))")
                    
                    resolver.state = .fulfilled(mappedResult)
                } catch {
                    resolver.state = .rejected(error)
                    return
                }
            }
        }
    }
    
    func create<DomainEntity: Mappable>(objects: [DomainEntity]) -> Finalizer<[DomainEntity]> {
        Finalizer<[DomainEntity]> { resolver in
            self.privateManagedContext.performBackgroundTask { privateManagedContext in
                let entities: [NSManagedObject] = objects.compactMap {
                    guard let entity = self.createNSManagedObject(
                        DomainEntity.Persistance.self,
                        in: privateManagedContext
                    ) else {
                        return nil
                    }
                    
                    entity.setupDefaultValues()
                    $0.mapManagedObject(target: entity)
                    
                    return entity
                }
                
                do {
                    try privateManagedContext.saveIfNeeded()
                    
                } catch {
                    resolver.state = .rejected(error)
                    return
                }
                
                let privateObjectIDs = entities.map { $0.objectID }
                
                self.mainManagedContext.performAndWait {
                    do {
                        let mainEntities: [NSManagedObject] = privateObjectIDs.compactMap {
                            let objectID = $0
                            guard
                                let mainEntity = self.mainManagedContext.insertedObjects.first(
                                    where: { $0.objectID == objectID }
                                )
                            else {
                                return nil
                            }
                            
                            return mainEntity
                        }
                            
                        try self.mainManagedContext.obtainPermanentIDs(
                            for: Array(self.mainManagedContext.insertedObjects)
                        )
                        
                        try self.mainManagedContext.saveIfNeeded()
                        
                        let mappedObjects = try mainEntities.map { try DomainEntity.mapFrom($0) }
                        
                        print("CoreData: Created entities \(String(describing: DomainEntity.Persistance.self))")
                        
                        resolver.state = .fulfilled(mappedObjects)
                    } catch {
                        resolver.state = .rejected(error)
                    }
                }
            }
        }
    }
    
    func save<DomainEntity: Mappable>(objects: [DomainEntity]) -> Finalizer<Bool> {
        Finalizer<Bool> { resolver in
            self.privateManagedContext.performBackgroundTask { privateManagedContext in
                let managedObjects: [NSManagedObject] = objects.compactMap {
                    guard let managedObject = privateManagedContext.object(for: $0) else {
                        return nil
                    }

                    return managedObject
                }
                
                if managedObjects.count != objects.count {
                    resolver.state = .rejected(StorageContextError.noManagedObject)
                    return
                }
                
                objects.enumerated().forEach { $0.element.mapManagedObject(target: managedObjects[$0.offset]) }

                do {
                    try privateManagedContext.saveIfNeeded()
                } catch {
                    resolver.state = .rejected(error)
                    return
                }

                self.mainManagedContext.performAndWait {
                    do {
                        try self.mainManagedContext.saveIfNeeded()

                        print("CoreData: Saved entities \(String(describing: DomainEntity.Persistance.self))")

                        resolver.state = .fulfilled(true)
                    } catch {
                        resolver.state = .rejected(error)
                    }
                }
            }
        }
    }

    func deleteAll<DomainEntity: Mappable>(_ model: DomainEntity.Type) -> Finalizer<Bool> {
        Finalizer<Bool> { resolver in
            self.privateManagedContext.performBackgroundTask { privateManagedContext in

                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: DomainEntity.Persistance.self))
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                do {
                    let result = try privateManagedContext.execute(deleteRequest) as? NSBatchDeleteResult
                    let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
                    let changes = [NSDeletedObjectsKey : objectIDArray]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [privateManagedContext])
                    
                    try privateManagedContext.saveIfNeeded()
                } catch {
                    resolver.state = .rejected(error)
                }
                
                self.mainManagedContext.performAndWait {
                    do {
                        try self.mainManagedContext.saveIfNeeded()
                        
                        print("CoreData: Deleted all entity \(String(describing: DomainEntity.Persistance.self))")
                        
                        resolver.state = .fulfilled(true)
                    } catch {
                        resolver.state = .rejected(error)
                    }
                }
            }
        }
    }
}

private extension CoreDataStorageContext {
    func createNSManagedObject<Entity: Storable>(
        _ model: Entity.Type,
        in context: NSManagedObjectContext
    ) -> NSManagedObject? {
        guard
            let entityDescription = NSEntityDescription.entity(
                forEntityName: String(describing: model),
                in: context
            )
        else {
            return nil
        }
        
         
        return NSManagedObject(
            entity: entityDescription,
            insertInto: context
        )
    }
}
