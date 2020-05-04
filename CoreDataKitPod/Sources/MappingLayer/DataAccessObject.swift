//
//  DataAccessObject.swift
//  CheckScan
//
//  Created by Indir Amerkhanov on 19.12.2019.
//  Copyright © 2019 Warefly. All rights reserved.
//
//

import CoreData

public class DataAccessObject: DataAccessObjectProtocol {
    public static let shared = DataAccessObject()
    
    private let storageContext: CoreDataStorageContext

    public required init(storageContext: CoreDataStorageContext = CoreDataStorageContext()) {
        self.storageContext = storageContext
    }

    public func save<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<DomainEntity> {
        if let primaryKey = DomainEntity.primaryKey {
            return save(object: object, primaryKey: primaryKey)
        }
        
        return Finalizer<DomainEntity> { resolver in
            if object.objectContainer?.objectID != nil {
                self.storageContext.save(object: object).done { success in
                    if success {
                        resolver.state = .fulfilled(object)
                    } else {
                        resolver.state = .rejected(StorageContextError.saveError)
                    }
                }.catch(errorHandler: { resolver.state = .rejected($0) })
                return
            }
            
            self.storageContext.create(object: object).done { newObject in
                resolver.state = .fulfilled(newObject)
            }.catch(errorHandler: { resolver.state = .rejected($0) })
        }
    }
    
    public func save<DomainEntity: Mappable>(objects: [DomainEntity]) -> Finalizer<[DomainEntity]> {
        if let primaryKey = DomainEntity.primaryKey {
            return save(objects: objects, primaryKey: primaryKey)
        }
        
        return Finalizer<[DomainEntity]> { resolver in
            let objectsWithID = objects.filter { $0.objectContainer?.objectID != nil }
            let objectsWithoutIDs = objects.filter { $0.objectContainer?.objectID == nil }
            
            let creatingBlock: ([DomainEntity]) -> Void = { savedObjects in
                if objectsWithoutIDs.isEmpty == false {
                    self.storageContext.create(objects: objectsWithoutIDs).done { objects in
                        resolver.state = .fulfilled(objects + savedObjects)
                    }.catch { resolver.state = .rejected($0) }
                    return
                }
                
                resolver.state = .fulfilled(savedObjects)
            }
            
            if objectsWithID.isEmpty == false {
                self.storageContext.save(objects: objectsWithID).done { success in
                    if success {
                        creatingBlock(objectsWithID)
                    } else {
                        resolver.state = .rejected(StorageContextError.saveError)
                    }
                }.catch(errorHandler: { resolver.state = .rejected($0) })
                return
            }
            
            creatingBlock([])
        }
    }

    public func update<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<Bool> {
        storageContext.save(object: object)
    }
    
    public func delete<DomainEntity: Mappable>(object: DomainEntity) -> Finalizer<Bool> {
        storageContext.delete(object: object)
    }
    
    public func deleteAll<DomainEntity: Mappable>(_ model: DomainEntity.Type) -> Finalizer<Bool> {
        storageContext.deleteAll(model)
    }
    
    public func fetch<DomainEntity: Mappable>(
        _ model: DomainEntity.Type,
        predicate: NSPredicate?,
        sorted: Sorted?
    ) -> Finalizer<[DomainEntity]> {
        storageContext.fetch(model, predicate: predicate, sorted: sorted)
    }
}

extension DataAccessObject {
    func save<DomainEntity: Mappable>(object: DomainEntity, primaryKey: String) -> Finalizer<DomainEntity> {
        Finalizer<DomainEntity> { resolver in
            self.save(objects: [object], primaryKey: primaryKey).done { objects in
                guard let firstObject = objects.first else {
                    resolver.state = .fulfilled(object)
                    return
                }
                
                resolver.state = .fulfilled(firstObject)
            }.catch(errorHandler: { resolver.state = .rejected($0) })
        }
    }
    
    
    func save<DomainEntity: Mappable>(objects: [DomainEntity], primaryKey: String) -> Finalizer<[DomainEntity]> {
        Finalizer<[DomainEntity]> { resolver in
            self.fetch(DomainEntity.self, predicate: nil, sorted: nil).done { items in
                var existingObjects: [DomainEntity] = []
                var notExistingObjects: [DomainEntity] = []
                
                for object in objects {
                    if
                        let intId = object.getIntValue(for: primaryKey),
                        let fetchedObject = items.first(where: { intId == $0.getIntValue(for: primaryKey) })
                    {
                        existingObjects.append(
                            object.withOtherObject(fetchedObject)
                        )
                        continue
                    } else if
                        let stringId = object.getStringValue(for: primaryKey),
                        let fetchedObject = items.first(where: { stringId == $0.getStringValue(for: primaryKey) })
                    {
                        existingObjects.append(
                            object.withOtherObject(fetchedObject)
                        )
                        continue
                    }
                
                    notExistingObjects.append(object)
                }
                
                let creatingBlock: ([DomainEntity]) -> Void = { savedObjects in
                    if notExistingObjects.isEmpty == false {
                        self.storageContext.create(objects: notExistingObjects).done { objects in
                            resolver.state = .fulfilled(objects + savedObjects)
                        }.catch { resolver.state = .rejected($0) }
                        return
                    }
                    
                    resolver.state = .fulfilled(savedObjects)
                }
                
                if existingObjects.isEmpty == false {
                    self.storageContext.save(objects: existingObjects).done { success in
                        if success {
                            creatingBlock(existingObjects)
                        } else {
                            resolver.state = .rejected(StorageContextError.saveError)
                        }
                    }.catch(errorHandler: { resolver.state = .rejected($0) })
                    return
                }
                
                creatingBlock([])
            }.catch { resolver.state = .rejected($0) }
        }
    }
}
