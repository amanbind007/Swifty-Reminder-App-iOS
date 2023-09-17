//
//  MyListView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 17/09/23.
//

import SwiftUI

struct MyListView: View {
    let myLists : FetchedResults<MyList>
    
    var body: some View {
        
        NavigationStack{
            if myLists.isEmpty {
                Text("No Reminders Found")
            }
            else{
                ForEach(myLists) { listItem in
                    VStack{
                        MyListCellView(myList: listItem)
                            .padding(.horizontal)
                        Divider()
                    }
                }
                
            }
        }
        
        
    }
}

//struct MyListView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyListView()
//    }
//}
