//
//  SelectListView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 21/09/23.
//

import SwiftUI

struct SelectListView: View {
    @FetchRequest(sortDescriptors: []) private var myListsFetchResults: FetchedResults<MyList>
    @Binding var selectedList: MyList?

    var body: some View {
        List(myListsFetchResults) { myList in
            HStack {
                HStack {
                    ListPumpkinIcon(myList: myList)
                        .frame(width: 30, height: 30)
                    Text(myList.name)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    self.selectedList = myList
                }

                Spacer()

                if selectedList == myList {
                    Image(systemName: "checkmark")
                        .foregroundColor(.pumpkin)
                }
            }
        }
    }
}

struct SelectListView_Previews: PreviewProvider {
    static var previews: some View {
        SelectListView(selectedList: .constant(PreviewData.myList))
            .environment(\.managedObjectContext, CoreDataProvider.shared.persistentContainer.viewContext)
    }
}
