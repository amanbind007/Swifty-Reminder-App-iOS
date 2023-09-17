//
//  ReminderService.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 17/09/23.
//

import Foundation
import CoreData
import UIKit


class ReminderService{
    static var viewContext : NSManagedObjectContext{
        CoreDataProvider.shared.persistentContainer.viewContext
    }
    
    static func save() throws {
        try viewContext.save()
    }
    
    static func saveMyList(_ name: String, _ color: UIColor) throws {
        let myList = MyList(context: viewContext)
        myList.name = name
        myList.color = color
        try save()
    }
    
    
    
    
}
