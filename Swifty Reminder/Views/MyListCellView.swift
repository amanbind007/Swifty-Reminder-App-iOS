//
//  MyListCellView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 17/09/23.
//

import SwiftUI

struct MyListCellView: View {
    
    let myList: MyList
    var body: some View {
        
        HStack{
            Image(systemName: "line.3.horizontal.circle.fill")
                .foregroundColor(Color(uiColor: myList.color))
            
            Text(myList.name)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .opacity(0.4)
                .padding([.trailing], 10)
        }
    }
}

struct MyListCellView_Previews: PreviewProvider {
    static var previews: some View {
        MyListCellView(myList: PreviewData.myList)
    }
}
