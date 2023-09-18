//
//  File.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 18/09/23.
//

import Foundation

class PreviewData {
    
    static var myList : MyList {
        let viewContext = CoreDataProvider.shared.persistentContainer.viewContext
        let request = MyList.fetchRequest()
        return (try? viewContext.fetch(request).first) ?? MyList()
    }
    
    static var reminder : Reminder {
        let viewContext = CoreDataProvider.shared.persistentContainer.viewContext
        let request = Reminder.fetchRequest()
        return (try? viewContext.fetch(request).first) ?? Reminder(context: viewContext)
    }

}
