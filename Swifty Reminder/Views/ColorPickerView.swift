//
//  ColorPickerView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 16/09/23.
//

import SwiftUI

struct ColorPickerView: View {
    
    @State var selectedColor : Color
    
    let colors : [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        HStack{
            ForEach(colors, id: \.self) { color in
                Circle()
                    .fill()
                    .foregroundColor(color)
                    .padding(3)
                    .overlay {
                        Circle()
                            .stroke(lineWidth: 3)
                            .foregroundColor(selectedColor == color ? .gray : .clear)
                    }
                    .onTapGesture {
                        selectedColor = color
                    }
            }
 
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 100)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        
    }
}

struct ColorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerView(selectedColor: Color.yellow)
            .previewLayout(.sizeThatFits)
        
    }
}
