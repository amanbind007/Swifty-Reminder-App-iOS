//
//  MyList+CoreDataProperties.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 16/09/23.
//

import Foundation
import CoreData
import UIKit

extension MyList {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MyList> {
        return NSFetchRequest<MyList>(entityName: "MyList")
    }
    
    @NSManaged public var name: String
    @NSManaged public var color: UIColor

}

extension MyList: Identifiable {
    
}

// MARK: - Generated accessor for notes

extension MyList {
    
}

