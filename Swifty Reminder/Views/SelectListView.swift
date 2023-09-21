//
//  SelectListView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 21/09/23.
//

import SwiftUI

struct SelectListView: View {
    
    @FetchRequest(sortDescriptors: []) private var myListsFetchResults: FetchedResults<MyList>
    @Binding var selectist: MyList?
    
    var body: some View {
        List(myListsFetchResults) { myList in
            HStack{
                
            }
        }
    }
}

#Preview {
    SelectListView(selectist: .constant(PreviewData.myList))
        .environment(\.managedObjectContext, CoreDataProvider.shared.persistentContainer.viewContext)
}
