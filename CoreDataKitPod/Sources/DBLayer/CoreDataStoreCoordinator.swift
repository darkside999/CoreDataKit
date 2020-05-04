//
//  CoreDataStoreCoordinator.swift
//  CheckScan
//
//  Created by Indir Amerkhanov on 19.12.2019.
//  Copyright © 2019 Warefly. All rights reserved.
//

import CoreData

enum StoreType: String {
    case sqLiteStoreType
    case inMemoryStoreType
}

class CoreDataStoreCoordinator {
    static func persistentStoreCoordinator(modelName: String? = nil, storeType: StoreType = .sqLiteStoreType) -> NSPersistentStoreCoordinator? {
        do {
            return try NSPersistentStoreCoordinator.coordinator(modelName: modelName, storeType: storeType)
        } catch {
            print("CoreData: Unresolved error \(error)")
        }
        
        return nil
    }
}


