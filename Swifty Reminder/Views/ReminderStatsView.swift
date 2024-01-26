//
//  SwiftUIView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 01/10/23.
//

import SwiftUI

struct ReminderStatsView: View {
    let icon: String
    let title: String
    let count: Int?
    let iconColor: Color

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title)
                    Text(title)
                        .opacity(0.8)
                }
                Spacer()
                if let count = count {
                    Text("\(count)")
                        .font(.largeTitle)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("CardBackground", bundle: Bundle(path: "Assets")))
            .clipShape(RoundedRectangle(cornerRadius: 15.0))
        }
    }
}
