//
//  Receipt.swift
//  CoreDataKitTest
//
//  Created by Indir Amerkhanov on 04.05.2020.
//  Copyright © 2020 Indir Amerkhanov. All rights reserved.
//

import Foundation
import CoreDataKit

extension StoredReceipt {
    public override func setupDefaultValues() {
        id = 0
        date = Date()
        sum = 0
    }
}

struct Receipt: Mappable {
    let id: Int
    let date: Date
    let sum: Int
    
    let objectContainer: ManagedObjectContainer?
    
    static var primaryKey: String? { "id" }
    
    func mapManagedObject(target: StoredReceipt) {
        target.date = date
        target.sum = Int32(sum)
        target.id = Int32(id)
    }
    
    static func mapFrom(_ managedObject: StoredReceipt) throws -> Receipt {
        Receipt(
            id: Int(managedObject.id),
            date: managedObject.date ?? Date(),
            sum: Int(managedObject.sum),
            objectContainer: ManagedObjectContainer(objectID: managedObject.objectID)
        )
    }
    
    func withOtherObject(_ object: Receipt) -> Receipt {
        Receipt(
            id: id,
            date: date,
            sum: sum,
            objectContainer: object.objectContainer
        )
    }
}
