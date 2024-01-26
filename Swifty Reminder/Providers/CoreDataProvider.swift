//
//  CoreDataProvider.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/19/23.
//

import CoreData
import Foundation

class CoreDataProvider {
    static let shared = CoreDataProvider()
    let persistentContainer: NSPersistentContainer
    
    private init() {
        // register transformers
        ValueTransformer.setValueTransformer(UIColorTransformer(), forName: NSValueTransformerName("UIColorTransformer"))
        
        persistentContainer = NSPersistentContainer(name: "RemindersModel")
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("Error initializing RemindersModel \(error)")
            }
        }
    }
}
