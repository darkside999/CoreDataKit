//
//  NSPersistenceStoreCoordinatorExtensions.swift
//  CoreDataTest
//
//  Created by Indir Amerkhanov on 19.03.2020.
//  Copyright © 2020 Indir Amerkhanov. All rights reserved.
//

import Foundation
import CoreData

extension NSPersistentStoreCoordinator {

    /// NSPersistentStoreCoordinator error types
    public enum CoordinatorError: Error {
        /// .momd file not found
        case modelFileNotFound
        /// NSManagedObjectModel creation fail
        case modelCreationError
        /// Gettings document directory fail
        case storePathNotFound
    }

    /// Return NSPersistentStoreCoordinator object
    static func coordinator(modelName: String? = nil, storeType: StoreType) throws -> NSPersistentStoreCoordinator? {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            throw CoordinatorError.modelFileNotFound
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoordinatorError.modelCreationError
        }

        let persistentContainer = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        if storeType == .inMemoryStoreType {
            try persistentContainer.configureInMemoryStore()
        } else {
            try persistentContainer.configureSQLiteStore(name: modelName!)
        }
        return persistentContainer
    }

}

private extension NSPersistentStoreCoordinator {
    func configureSQLiteStore(name: String) throws {
        guard
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        else {
            throw CoordinatorError.storePathNotFound
        }
        
        let url = documents.appendingPathComponent("\(name).sqlite")
        
        do {
            let options: [String: Any] = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
            try self.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            throw error
        }
    }

    func configureInMemoryStore() throws {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false // Make it simpler in test env
        self.addPersistentStore(with: description) { (description, error) in
            // Check if the data store is in memory
            precondition( description.type == NSInMemoryStoreType )

            // Check if creating container wrong
            if let error = error {
                fatalError("Create an in-mem coordinator failed \(error)")
            }
        }
    }

}
