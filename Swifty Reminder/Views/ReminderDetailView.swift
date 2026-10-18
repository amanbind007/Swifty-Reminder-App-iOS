//
//  ReminderDetailView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 20/09/23.
//

import SwiftUI

struct ReminderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var reminder: Reminder
    @State private var editConfig: ReminderEditConfig
    
    private var isFormValid: Bool {
        !editConfig.title.isEmpty
    }
    
    init(reminder: Binding<Reminder>) {
        _reminder = reminder
        // Load the saved values once. Reloading in onAppear flipped the date/time toggles,
        // which reset them to now, and wiped edits when coming back from the list picker.
        _editConfig = State(initialValue: ReminderEditConfig(reminder: reminder.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        TextField("Title", text: $editConfig.title)
                        TextField("Notes", text: $editConfig.notes ?? "")
                    }
                    
                    Section {
                        Toggle(isOn: $editConfig.hasDate) {
                            Image(systemName: "moon.stars")
                                .foregroundColor(.pumpkin)
                        }
                        
                        if editConfig.hasDate {
                            DatePicker("Select Date", selection: $editConfig.reminderDate ?? Date(), displayedComponents: .date)
                        }
                        
                        Toggle(isOn: $editConfig.hasTime) {
                            Image(systemName: "hourglass")
                                .foregroundColor(.candleGlow)
                        }
                        
                        if editConfig.hasTime {
                            DatePicker("Select Date", selection: $editConfig.reminderTime ?? Date(), displayedComponents: .hourAndMinute)
                        }
                        
                        Section {
                            NavigationLink {
                                SelectListView(selectedList: $editConfig.list)
                            } label: {
                                HStack {
                                    Text("List")
                                    Spacer()
                                    Text(editConfig.list?.name ?? "")
                                }
                            }
                        }
                    }.onChange(of: editConfig.hasDate) { hasDate in
                        if hasDate {
                            editConfig.reminderDate = Date()
                        }
                    }.onChange(of: editConfig.hasTime) { hasTime in
                        if hasTime {
                            editConfig.reminderTime = Date()
                        }
                    }
                }.listStyle(.insetGrouped)
                    .tint(Color.pumpkin)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Details")
                        .foregroundColor(.pumpkin)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        do {
                            // Also reschedules or cancels the reminder's notification
                            _ = try ReminderService.updateReminder(reminder: reminder, editConfig: editConfig)
                        } catch {
                            print(error)
                        }
                        dismiss()
                    }.disabled(!isFormValid)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReminderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderDetailView(reminder: .constant(PreviewData.reminder))
    }
}
