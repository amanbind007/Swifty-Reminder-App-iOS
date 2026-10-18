//
//  ColorPickerView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 16/09/23.
//

import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    
    let colors: [Color] = [.pumpkin, .ember, .candleGlow, .bloodRed, .witchPurple, .slimeGreen, .boneWhite]
    
    var body: some View {
        HStack {
            ForEach(colors, id: \.self) { color in
                Circle()
                    .fill()
                    .foregroundColor(color)
                    .padding(3)
                    .overlay {
                        Circle()
                            .stroke(lineWidth: 3)
                            .foregroundColor(selectedColor == color ? .boneWhite : .clear)
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
    @State static var color: Color = .pumpkin
    static var previews: some View {
        ColorPickerView(selectedColor: $color)
    }
}
