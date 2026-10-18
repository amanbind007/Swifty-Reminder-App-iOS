//
//  WitchBubbleView.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import SwiftUI

/// Hexelda's speech bubble, which drops in from the top when she taunts you. Tap it to chat back.
struct WitchBubbleView: View {
    @ObservedObject private var witch = WitchTaunter.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingChat = false

    var body: some View {
        VStack {
            if let text = witch.bubble {
                bubble(text)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: witch.bubble != nil)
        .sheet(isPresented: $showingChat) {
            HexeldaChatView()
        }
        .task {
            // Greet on launch, once the home screen has had a moment to appear
            try? await Task.sleep(for: .seconds(1.5))
            witch.greet()
        }
        .onChange(of: scenePhase) { phase in
            // ...and when coming back to the app (at most every 10 minutes)
            if phase == .active {
                witch.greet()
            }
        }
    }

    private func bubble(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🧙‍♀️")
                .font(.system(size: 34))

            VStack(alignment: .leading, spacing: 3) {
                Text("Hexelda")
                    .font(.caption.bold())
                    .foregroundColor(.pumpkin)
                if text.isEmpty {
                    Text("cackling…")
                        .italic()
                        .opacity(0.7)
                } else {
                    Text(text)
                }
                Text("Tap to talk back")
                    .font(.caption2)
                    .opacity(0.5)
            }
            .font(.subheadline)
            .foregroundColor(.boneWhite)

            Spacer(minLength: 0)

            Button {
                witch.dismissBubble()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundColor(.boneWhite.opacity(0.6))
                    .padding(4)
            }
        }
        .padding(12)
        .background(Color.cauldron)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.witchPurple.opacity(0.7), lineWidth: 1.5)
        )
        .shadow(color: Color.witchPurple.opacity(0.5), radius: 14)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            witch.dismissBubble()
            showingChat = true
        }
    }
}

/// A chat with Hexelda. Her taunts appear here too, so you can answer them.
struct HexeldaChatView: View {
    @ObservedObject private var witch = WitchTaunter.shared
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            if witch.messages.isEmpty {
                                Text("Hexelda is watching you make your lists, mortal. Say something... if you dare.")
                                    .italic()
                                    .foregroundColor(.boneWhite.opacity(0.6))
                            }
                            ForEach(witch.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            if witch.isThinking {
                                Text("Hexelda is stirring her cauldron…")
                                    .italic()
                                    .font(.footnote)
                                    .foregroundColor(.boneWhite.opacity(0.6))
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollToBottom(proxy)
                    }
                    .onChange(of: witch.messages.count) { _ in
                        withAnimation {
                            scrollToBottom(proxy)
                        }
                    }
                }

                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Talk back to Hexelda…", text: $draft, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        witch.send(draft)
                        draft = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || witch.isThinking)
                }
                .padding()
                .background(Color.cauldron)
            }
            .background(Color.midnight.ignoresSafeArea())
            .navigationTitle("Hexelda 🧙‍♀️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        HexeldaSettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = witch.messages.last?.id {
            proxy.scrollTo(last, anchor: .bottom)
        }
    }
}

private struct ChatBubble: View {
    let message: WitchTaunter.Message

    var body: some View {
        HStack {
            if message.fromUser {
                Spacer(minLength: 40)
            }
            Text(message.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(message.fromUser ? Color.midnight : Color.boneWhite)
                .background(message.fromUser ? Color.pumpkin : Color.cauldron)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            if !message.fromUser {
                Spacer(minLength: 40)
            }
        }
    }
}

/// Turn Hexelda on or off, and give her a Gemma 4 key so she can write her own lines.
struct HexeldaSettingsView: View {
    @ObservedObject private var witch = WitchTaunter.shared
    @State private var keyDraft = ""

    var body: some View {
        Form {
            Section {
                Toggle("Let Hexelda taunt me", isOn: $witch.isEnabled)
            } footer: {
                Text("She pops up when you add lists, reminders and timers.")
            }
            .listRowBackground(Color.cauldron)

            Section {
                if witch.hasAPIKey {
                    Label("Gemma 4 key saved", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.slimeGreen)
                    Button("Remove key", role: .destructive) {
                        witch.saveAPIKey("")
                    }
                } else {
                    SecureField("Google AI Studio API key", text: $keyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Save key") {
                        witch.saveAPIKey(keyDraft)
                        keyDraft = ""
                    }
                    .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Link("Get a free key from Google AI Studio", destination: URL(string: "https://aistudio.google.com/apikey")!)
                }
            } header: {
                Text("Gemma 4")
            } footer: {
                Text(witch.hasAPIKey
                     ? "Hexelda writes her lines with Google's Gemma 4. The names of the lists, reminders and timers you add, and anything you type to her, are sent to Google to do that."
                     : "Without a key, Hexelda reads from her built-in book of taunts. Add one and she'll write fresh ones with Google's Gemma 4. The key stays in this iPhone's keychain.")
            }
            .listRowBackground(Color.cauldron)
        }
        .scrollContentBackground(.hidden)
        .background(Color.midnight.ignoresSafeArea())
        .navigationTitle("Hexelda's Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WitchBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        HexeldaChatView()
    }
}
