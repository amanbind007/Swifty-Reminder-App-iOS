//
//  MyList+CoreDataProperties.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/19/23.
//

import CoreData
import Foundation
import UIKit

public extension MyList {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MyList> {
        return NSFetchRequest<MyList>(entityName: "MyList")
    }

    @NSManaged var name: String
    @NSManaged var color: UIColor
    @NSManaged var reminders: NSSet?
}

extension MyList: Identifiable {}

// MARK: Generated accessors for notes

public extension MyList {
    @objc(addRemindersObject:)
    @NSManaged func addToReminders(_ value: Reminder)

    @objc(removeRemindersObject:)
    @NSManaged func removeFromReminders(_ value: Reminder)

    @objc(addReminders:)
    @NSManaged func addToReminders(_ values: NSSet)

    @objc(removeReminders:)
    @NSManaged func removeFromReminders(_ values: NSSet)
}
