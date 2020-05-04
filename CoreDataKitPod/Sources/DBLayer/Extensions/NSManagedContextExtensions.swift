//
//  NSManagedContext+SaveIfNeeded.swift
//
//  Created by Indir Amerkhanov on 01.04.2020.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
    
    func performBackgroundTask(performTask: @escaping (NSManagedObjectContext) -> Void) {
        self.perform {
            performTask(self)
        }
    }
    
    func object<DomainEntity: Mappable>(for entity: DomainEntity) -> DomainEntity.Persistance? {
        if let primaryKey = DomainEntity.primaryKey {
            let posiblePredicate: NSPredicate?
            
            if let intId = entity.getIntValue(for: primaryKey) {
                posiblePredicate = NSPredicate(format: "\(primaryKey) = %d", intId)
            } else if let stringId = entity.getStringValue(for: primaryKey) {
                posiblePredicate = NSPredicate(format: "\(primaryKey) = %@", stringId)
            } else {
                posiblePredicate = nil
            }
            
            if let predicate = posiblePredicate {
                let fetchRequest = DomainEntity.Persistance.getFetchRequest()
                fetchRequest.predicate = predicate
                
                let result = try? fetch(fetchRequest)
                
                if let object = result?.first {
                    return object
                }
            }
        }
        
        guard let objectId = entity.objectContainer?.objectID else {
            return nil
        }
        
        do {
            return try existingObject(with: objectId) as? DomainEntity.Persistance
        } catch {
            return nil
        }
    }
}
