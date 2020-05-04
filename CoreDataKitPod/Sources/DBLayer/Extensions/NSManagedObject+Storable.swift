//
//  NSManagedObject+Storable.swift
//  CheckScan
//
//  Created by Indir Amerkhanov on 19.12.2019.
//  Copyright © 2019 Warefly. All rights reserved.
//

import CoreData

extension NSManagedObject: Storable {
    @objc open func setupDefaultValues() {
        fatalError("implement this function")
    }
    
    public func updateOrCreateChildTarget<Entity: Mappable>(
        _ target: Entity.Persistance?,
        with object: Entity?
    ) -> Entity.Persistance? {
        guard let object = object else {
            return nil
        }
        
        guard target == nil else {
            
            guard let target = target else { return nil }
            
            object.mapManagedObject(target: target)
            
            return target
        }
        
        guard let managedContext = managedObjectContext else {
            return nil
        }
        
        if let existingObject = managedContext.object(for: object) {
            object.mapManagedObject(target: existingObject)
            return existingObject
        }
        
        guard
            let entityDescription = NSEntityDescription.entity(
                forEntityName: String(describing: Entity.Persistance.self),
                in: managedContext
            )
        else {
            return nil
        }
        
        guard let entity = NSManagedObject(entity: entityDescription, insertInto: managedContext) as? Entity.Persistance else { return nil }
        entity.setupDefaultValues()
        
        object.mapManagedObject(target: entity)
        
        return entity
    }
    
    public func updateOrCreateChildTargets<Entity: Mappable>(
        _ targets: [Entity.Persistance]?,
        with objects: [Entity]?
    ) -> [Entity.Persistance] {
        objects?.compactMap {
            let object = $0
            guard let targetObject = targets?.first(
                where: { $0.objectID == object.objectContainer?.objectID }
            ) else {
                return updateOrCreateChildTarget(nil, with: object)
            }
            
            return updateOrCreateChildTarget(targetObject, with: object)
        } ?? []
    }
    
    public func updateOrCreateChildTargets<Entity: Mappable>(
        _ targets: NSSet?,
        with objects: [Entity]?
    ) -> NSSet {
        NSSet(
            array: updateOrCreateChildTargets(
                targets?.compactMap { $0 as? Entity.Persistance },
                with: objects
            )
        )
    }
    
    public func updateOrCreateChildTargets<Entity: Mappable>(
        _ targets: NSOrderedSet?,
        with objects: [Entity]?
    ) -> NSOrderedSet {
        NSOrderedSet(
            array: updateOrCreateChildTargets(
                targets?.compactMap { $0 as? Entity.Persistance },
                with: objects
            )
        )
    }
}
