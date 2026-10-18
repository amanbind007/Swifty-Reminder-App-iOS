//
//  GemmaClient.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import Foundation

/// Talks to Google's Gemma 4 through the Gemini API (generativelanguage.googleapis.com).
/// Needs a Google AI Studio API key, which the user adds in Hexelda's settings.
struct GemmaClient {
    /// The mixture-of-experts Gemma 4 model: quick replies, good enough for one-liners
    static let model = "gemma-4-26b-a4b-it"

    struct Turn {
        let fromUser: Bool
        let text: String
    }

    enum GemmaError: Error {
        case badStatus(Int)
        case emptyReply
    }

    let apiKey: String

    /// Sends the conversation and returns Gemma's reply text.
    func reply(system: String, turns: [Turn], maxTokens: Int = 150) async throws -> String {
        do {
            return try await send(system: system, turns: turns, maxTokens: maxTokens, skipThinking: true)
        } catch GemmaError.badStatus(400) {
            // If this model doesn't accept the thinking setting, ask again without it
            return try await send(system: system, turns: turns, maxTokens: maxTokens, skipThinking: false)
        }
    }

    private func send(system: String, turns: [Turn], maxTokens: Int, skipThinking: Bool) async throws -> String {
        var request = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(Self.model):generateContent")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let body = Request(
            systemInstruction: Content(role: nil, parts: [Part(text: system)]),
            contents: Self.alternating(turns).map { Content(role: $0.fromUser ? "user" : "model", parts: [Part(text: $0.text)]) },
            generationConfig: GenerationConfig(
                temperature: 1.0,
                maxOutputTokens: maxTokens,
                // "minimal" turns thinking off, so a one-line taunt comes back fast
                thinkingConfig: skipThinking ? ThinkingConfig(thinkingLevel: "minimal") : nil
            )
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 200 else { throw GemmaError.badStatus(status) }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let text = (decoded.candidates?.first?.content?.parts ?? [])
            .filter { $0.thought != true }
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw GemmaError.emptyReply }
        return text
    }

    /// The API wants the chat to start with the user and take turns, so merge back-to-back
    /// messages from the same side and drop anything the model said before the user spoke.
    private static func alternating(_ turns: [Turn]) -> [Turn] {
        var merged: [Turn] = []
        for turn in turns.drop(while: { !$0.fromUser }) {
            if let last = merged.last, last.fromUser == turn.fromUser {
                merged[merged.count - 1] = Turn(fromUser: turn.fromUser, text: last.text + "\n\n" + turn.text)
            } else {
                merged.append(turn)
            }
        }
        return merged
    }

    // MARK: - Request and response JSON

    private struct Part: Codable {
        var text: String?
        var thought: Bool?
    }

    private struct Content: Codable {
        var role: String?
        var parts: [Part]?
    }

    private struct ThinkingConfig: Encodable {
        var thinkingLevel: String
    }

    private struct GenerationConfig: Encodable {
        var temperature: Double
        var maxOutputTokens: Int
        var thinkingConfig: ThinkingConfig?
    }

    private struct Request: Encodable {
        var systemInstruction: Content
        var contents: [Content]
        var generationConfig: GenerationConfig
    }

    private struct Response: Decodable {
        struct Candidate: Decodable {
            var content: Content?
        }

        var candidates: [Candidate]?
    }
}
