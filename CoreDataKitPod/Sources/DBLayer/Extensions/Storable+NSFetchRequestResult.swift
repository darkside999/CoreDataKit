//
//  Storable+NSFetchRequestResult.swift
//  CoreDataTest
//
//  Created by Indir Amerkhanov on 19.03.2020.
//  Copyright © 2020 Indir Amerkhanov. All rights reserved.
//

import CoreData

extension Storable where Self: NSManagedObject {
    static func getFetchRequest() -> NSFetchRequest<Self> {
        NSFetchRequest<Self>(entityName: String(describing: Self.self))
    }
}
