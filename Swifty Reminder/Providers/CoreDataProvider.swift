//
//  CoreDataProvider.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 15/09/23.
//

import Foundation
import CoreData

class CoreDataProvider{
    static let shared = CoreDataProvider()
    let persistentContainer = NSPersistentContainer(name: "RemindersModel")
    
    
    //It is private so that we cannot new object of it.
    // And only `shared` will be used (Singleton Design Pattern)
    private init(){
        
        persistentContainer.loadPersistentStores { description, error in
            if let error {
                fatalError("Error initializing RemindersModel: \(error)")
            }
        }
        
    }
    
}
