//
//  ViewController.swift
//  CoreDataKitTest
//
//  Created by Indir Amerkhanov on 03.05.2020.
//  Copyright © 2020 Indir Amerkhanov. All rights reserved.
//

import UIKit
import CoreDataKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dataManager = DataAccessObject.shared
        dataManager.save(
            object: Receipt(
                id: 1,
                date: Date(),
                sum: 1000,
                objectContainer: nil
            )
        )
        .done(completionHandler: { print($0) })
        .catch(errorHandler: { print($0) })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dataManager.fetch(Receipt.self, predicate: nil, sorted: nil)
            .done(completionHandler: { print($0) })
            .catch(errorHandler: { print($0) })
        }
    }


}

