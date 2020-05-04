//
//  CoreDataStorageContext.swift
//  CheckScan
//
//  Created by Indir Amerkhanov on 19.12.2019.
//  Copyright © 2019 Warefly. All rights reserved.
//

import CoreData

public enum ConfigurationType {
    case basic(identifier: String)
    case inMemory(identifier: String?)

    func identifier() -> String? {
        switch self {
        case .basic(let identifier): return identifier
        case .inMemory(let identifier): return identifier
        }
    }
}

public class CoreDataStorageContext {
    lazy var mainManagedContext: NSManagedObjectContext = {
        let managedContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        managedContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        return managedContext
    }()
    
    lazy var privateManagedContext: NSManagedObjectContext = {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        managedContext.parent = mainManagedContext
        managedContext.automaticallyMergesChangesFromParent = true
        managedContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        return managedContext
    }()

    public required init(configuration: ConfigurationType = .basic(identifier: "TestModel")) {
        switch configuration {
        case .basic:
            initDB(modelName: configuration.identifier(), storeType: .sqLiteStoreType)
        case .inMemory:
            initDB(modelName: configuration.identifier(), storeType: .inMemoryStoreType)
        }
    }

    private func initDB(modelName: String? = nil, storeType: StoreType) {
        guard let coordinator = CoreDataStoreCoordinator.persistentStoreCoordinator(
            modelName: modelName,
            storeType: storeType
        ) else {
            fatalError("Store coordinator is nil")
        }
        
        mainManagedContext.persistentStoreCoordinator = coordinator
    }
}

