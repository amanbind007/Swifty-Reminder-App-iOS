//
//  MyList+CoreDataClass.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/19/23.
//

import CoreData
import Foundation

@objc(MyList)
public class MyList: NSManagedObject {
    var remindersArray: [Reminder] {
        reminders?.allObjects.compactMap { ($0 as! Reminder) } ?? []
    }
}
