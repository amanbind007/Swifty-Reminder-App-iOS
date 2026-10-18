//
//  ReminderCellView.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/22/23.
//

import SwiftUI

enum ReminderCellEvents {
    case onInfo
    case onCheckChanged(Reminder, Bool)
    case onSelect(Reminder)
}

struct ReminderCellView: View {
    let reminder: Reminder
    
    let delay = Delay()
    
    @State private var checked: Bool = false
    
    let isSelected: Bool
    
    let onEvent: (ReminderCellEvents) -> Void
    
    private func formatDate(_ date: Date) -> String {
        if date.isToday {
            return "Today"
        } else if date.isTomorrow {
            return "Tomorrow"
        } else {
            return date.formatted(date: .numeric, time: .omitted)
        }
    }
    
    var body: some View {
        let haunt = checked ? HauntLevel.calm : reminder.hauntLevel()

        HStack {
            Image(systemName: checked ? "circle.inset.filled" : "circle")
                .font(.title2)
                .opacity(1)
                .foregroundColor(checked ? Color.candleGlow : Color.pumpkin)
                .onTapGesture {
                    checked.toggle()
                    
                    delay.cancel()
                    delay.performWork {
                        onEvent(.onCheckChanged(reminder, checked))
                    }
                }
            
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text(reminder.title ?? "")
                    if haunt >= .ghost {
                        GhostPerch(seed: reminder.hauntSeed)
                    }
                }
                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .opacity(0.4)
                        .font(.caption)
                }
                
                HStack {
                    if let reminderDate = reminder.reminderDate {
                        Text(formatDate(reminderDate))
                    }
                    
                    if let reminderTime = reminder.reminderTime {
                        Text(reminderTime.formatted(date: .omitted, time: .shortened))
                    }

                    if haunt > .calm {
                        Text("Overdue")
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .foregroundColor(haunt > .calm ? Color.ember : nil)
                    .opacity(haunt > .calm ? 0.9 : 0.4)
            }
            .modifier(Haunted(level: haunt, seed: reminder.hauntSeed))
            
            Spacer()
            Image(systemName: "info.circle.fill")
                .foregroundColor(.pumpkin)
                .opacity(isSelected ? 1.0 : 0.0)
                .onTapGesture {
                    onEvent(.onInfo)
                }
        }
        .onAppear(perform: {
            checked = reminder.isCompleted
        })
        .contentShape(Rectangle())
        .onTapGesture {
            onEvent(.onSelect(reminder))
        }
    }
}

struct ReminderCellView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderCellView(reminder: PreviewData.reminder, isSelected: true, onEvent: { _ in })
    }
}
