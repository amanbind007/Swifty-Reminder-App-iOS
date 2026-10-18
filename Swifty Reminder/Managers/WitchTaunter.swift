//
//  WitchTaunter.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import Foundation
import Security

/// Hexelda, the witch who taunts you as you add lists, reminders and timers, and chats back
/// when you tap her. She writes her lines with Gemma 4 when there's an API key, and falls back
/// to a built-in book of taunts when there isn't (or the internet lets her down).
final class WitchTaunter: ObservableObject {
    static let shared = WitchTaunter()

    enum Event {
        case appOpened
        case listCreated(name: String)
        case reminderAdded(title: String, listName: String)
        case timerStarted(label: String, minutes: Int)
    }

    struct Message: Identifiable, Equatable {
        let id = UUID()
        let fromUser: Bool
        let text: String
    }

    /// What's in the pop-up bubble: nil when hidden, empty while she's thinking
    @Published private(set) var bubble: String?
    @Published private(set) var isThinking = false
    @Published private(set) var messages: [Message] = []
    @Published private(set) var hasAPIKey: Bool
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }

    private static let enabledKey = "hexeldaEnabled"
    private static let apiKeyAccount = "gemmaAPIKey"
    /// Only ask Gemma for a taunt this often; in between she uses her book of taunts
    private static let aiCooldown: TimeInterval = 20
    /// Only greet the user this often when they come back to the app
    private static let greetingCooldown: TimeInterval = 10 * 60

    private var lastAICall = Date.distantPast
    private var lastGreeting = Date.distantPast
    private var hideTask: Task<Void, Never>?

    private init() {
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
        hasAPIKey = KeychainStore.read(Self.apiKeyAccount) != nil
    }

    private var client: GemmaClient? {
        KeychainStore.read(Self.apiKeyAccount).map { GemmaClient(apiKey: $0) }
    }

    func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        KeychainStore.write(trimmed.isEmpty ? nil : trimmed, for: Self.apiKeyAccount)
        hasAPIKey = !trimmed.isEmpty
    }

    // MARK: - Taunts

    /// Call from the main thread when the app opens or comes back to the foreground.
    func greet() {
        guard Date().timeIntervalSince(lastGreeting) > Self.greetingCooldown else { return }
        lastGreeting = Date()
        react(to: .appOpened)
    }

    /// Call from the main thread right after the user makes something.
    func react(to event: Event) {
        guard isEnabled, bubble == nil else { return }
        bubble = ""
        let stats = Self.reminderStats()

        Task { @MainActor in
            let taunt = await self.taunt(for: event, open: stats.open, overdue: stats.overdue)
            self.bubble = taunt
            self.messages.append(Message(fromUser: false, text: taunt))
            self.hideBubble(after: 7)
        }
    }

    func dismissBubble() {
        hideTask?.cancel()
        bubble = nil
    }

    private func hideBubble(after seconds: Double) {
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled {
                self.bubble = nil
            }
        }
    }

    @MainActor
    private func taunt(for event: Event, open: Int, overdue: Int) async -> String {
        let fallback = Self.bookTaunt(for: event, open: open, overdue: overdue)
        guard let client, Date().timeIntervalSince(lastAICall) > Self.aiCooldown else { return fallback }
        lastAICall = Date()

        let prompt = Self.describe(event)
            + " They have \(open) unfinished reminders, \(overdue) of them overdue. Taunt them."
        let reply = try? await client.reply(system: Self.persona + Self.tauntRules,
                                            turns: [GemmaClient.Turn(fromUser: true, text: prompt)])
        return reply ?? fallback
    }

    // MARK: - Chat

    /// Call from the main thread with what the user typed.
    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        messages.append(Message(fromUser: true, text: trimmed))
        isThinking = true

        Task { @MainActor in
            var reply = Self.noKeyReplies.randomElement() ?? ""
            if let client = self.client {
                let turns = self.messages.suffix(20).map { GemmaClient.Turn(fromUser: $0.fromUser, text: $0.text) }
                do {
                    reply = try await client.reply(system: Self.persona + Self.chatRules, turns: Array(turns), maxTokens: 220)
                } catch {
                    reply = "My crystal ball has gone cloudy... check your internet or your Gemma key, and try again."
                }
            }
            self.isThinking = false
            self.messages.append(Message(fromUser: false, text: reply))
        }
    }

    // MARK: - What she knows

    private static func reminderStats() -> (open: Int, overdue: Int) {
        let open = (try? ReminderService.viewContext.fetch(ReminderService.remindersByStatType(statType: .all))) ?? []
        return (open.count, open.filter { $0.hauntLevel() > .calm }.count)
    }

    private static func describe(_ event: Event) -> String {
        switch event {
        case .appOpened:
            return "The user just opened the app."
        case let .listCreated(name):
            return "The user just created a new to-do list called \"\(name)\"."
        case let .reminderAdded(title, listName):
            return "The user just added the reminder \"\(title)\" to their \"\(listName)\" list."
        case let .timerStarted(label, minutes):
            return label.isEmpty
                ? "The user just started a \(minutes)-minute timer."
                : "The user just started a \(minutes)-minute timer called \"\(label)\"."
        }
    }

    private static let persona = """
    You are Hexelda, a cackling Halloween witch who lives inside a spooky to-do app called Scary Calendar. \
    You love cauldrons, bats, black cats, rotting pumpkins, ghosts and puns, and you call the user "mortal" or "dearie". \
    Keep everything playful and PG: tease their procrastination and plans, never their looks, identity, health, \
    or anything personal, and never swear or be genuinely cruel.
    """

    private static let tauntRules = """
     Reply with a single taunt of one or two short sentences (under 30 words). \
    No quotation marks, emoji-free, no stage directions, no lists.
    """

    private static let chatRules = """
     The user is chatting with you. Stay in character and keep replies short (under 60 words). \
    If they ask for real help with their tasks, give it, wrapped in witchy flavour.
    """

    // MARK: - The book of taunts (used without a key, offline, or between Gemma calls)

    private static func bookTaunt(for event: Event, open: Int, overdue: Int) -> String {
        if case .appOpened = event {
            if open == 0 {
                return [
                    "Nothing left to do? Suspicious, mortal. Very suspicious.",
                    "An empty cauldron! Don't get comfortable, dearie. I'll be watching.",
                ].randomElement()!
            }
            if overdue > 0 {
                return [
                    "Back again? \(overdue) overdue \(overdue == 1 ? "reminder has" : "reminders have") been haunting this place while you were gone.",
                    "Welcome back, mortal. Your \(overdue) overdue \(overdue == 1 ? "reminder is" : "reminders are") rattling their chains for you. Hehehe!",
                ].randomElement()!
            }
            return [
                "Oh, it's YOU again. Shall we watch you procrastinate together?",
                "Welcome back, dearie. \(open) \(open == 1 ? "reminder is" : "reminders are") waiting... and so am I. Hehehe!",
                "Back so soon? The bats said you'd never get anything done today.",
            ].randomElement()!
        }
        if overdue > 2, Bool.random() {
            return "\(overdue) overdue reminders already haunt you, and you're adding more? Hehehe, the ghosts are thrilled."
        }
        switch event {
        case .appOpened:
            return ""  // handled above
        case let .listCreated(name):
            return [
                "A new list called “\(name)”? I give it a week before it rots like last year's pumpkin.",
                "“\(name)”... how ambitious. My cauldron has seen braver plans boil over.",
                "Another list, mortal? The spirits are placing bets on how much of it you'll finish.",
                "Ooh, “\(name)”. I'll hang it on my wall next to all your other good intentions.",
            ].randomElement()!
        case let .reminderAdded(title, _):
            return [
                "“\(title)”? Sure you will, dearie. And I'm a fairy godmother.",
                "Writing it down isn't the same as doing it. Hehehe!",
                "Into the cauldron goes “\(title)”. Let's see if it ever comes out done.",
                "“\(title)”... the bats and I will be watching. Closely.",
            ].randomElement()!
        case let .timerStarted(_, minutes):
            return [
                "A \(minutes)-minute timer? I've seen zombies move faster than you, mortal.",
                "Tick tock, dearie. When that timer screams, I'll be cackling.",
                "Racing the clock? The clock always wins. Just ask any skeleton.",
                "\(minutes) minutes, eh? My potion brews quicker, and it's mostly toad.",
            ].randomElement()!
        }
    }

    private static let noKeyReplies = [
        "I can't hear you without my crystal ball, mortal! Give me a Gemma key in my settings (the gear up top).",
        "Hehehe! Speak all you like, dearie. Without a Gemma key in my settings, I only read from my book of taunts.",
        "My crystal ball needs a Gemma key to talk back. Tap the gear, feed it one, and we'll have a proper chat.",
    ]
}

/// Keeps the Gemma API key in the iPhone's keychain rather than in the code or plain settings.
enum KeychainStore {
    private static let service = "SwiftyReminder.Hexelda"

    static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Saves the value, or deletes it when nil
    static func write(_ value: String?, for account: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        guard let value, let data = value.data(using: .utf8) else { return }
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }
}
