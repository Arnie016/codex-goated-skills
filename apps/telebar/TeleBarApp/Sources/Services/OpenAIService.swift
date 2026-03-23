import Foundation

struct OpenAIService {
    enum ServiceError: LocalizedError {
        case invalidResponse
        case emptyOutput

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "OpenAI returned an unreadable response."
            case .emptyOutput:
                return "The model did not return any text."
            }
        }
    }

    private let model = "gpt-4.1-mini"

    func summarize(
        thread: TelegramThread,
        bot: TelegramBotProfile?,
        tone: TeleBarModel.ReplyTone,
        instruction: String,
        apiKey: String
    ) async throws -> String {
        let system = """
        You are inside a macOS Telegram control center. Summarize the recent conversation clearly for the bot owner.
        Keep it compact and useful. Prefer short bullets or short sentences.
        Include:
        - what the user wants
        - urgency if any
        - what to do next
        Tone preference: \(tone.summaryStyle)
        """

        let user = """
        Bot: \(bot?.displayName ?? "Telegram bot")
        Thread: \(thread.title)
        Extra instruction: \(instruction.isEmpty ? "none" : instruction)

        Recent messages:
        \(transcript(for: thread.messages.prefix(8)))
        """

        return try await run(system: system, user: user, apiKey: apiKey)
    }

    func draftReply(
        thread: TelegramThread,
        bot: TelegramBotProfile?,
        tone: TeleBarModel.ReplyTone,
        instruction: String,
        apiKey: String
    ) async throws -> String {
        let system = """
        You write polished Telegram replies for a bot owner.
        Write only the reply text, no quotation marks, no markdown, no preamble.
        Keep it natural, concise, and ready to send.
        Tone: \(tone.replyStyle)
        """

        let user = """
        Bot: \(bot?.displayName ?? "Telegram bot")
        Thread: \(thread.title)
        Extra instruction: \(instruction.isEmpty ? "none" : instruction)

        Recent messages:
        \(transcript(for: thread.messages.prefix(8)))
        """

        return try await run(system: system, user: user, apiKey: apiKey)
    }

    private func run(system: String, user: String, apiKey: String) async throws -> String {
        let payload: [String: Any] = [
            "model": model,
            "input": [
                [
                    "role": "system",
                    "content": [["type": "input_text", "text": system]]
                ],
                [
                    "role": "user",
                    "content": [["type": "input_text", "text": user]]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ServiceError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data)
        let textOutput = extractText(from: json)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !textOutput.isEmpty else {
            throw ServiceError.emptyOutput
        }
        return textOutput
    }

    private func extractText(from value: Any) -> String? {
        if let string = value as? String, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return string
        }
        if let dictionary = value as? [String: Any] {
            if let outputText = dictionary["output_text"] as? String, !outputText.isEmpty {
                return outputText
            }
            for nested in dictionary.values {
                if let match = extractText(from: nested) {
                    return match
                }
            }
        }
        if let array = value as? [Any] {
            for item in array {
                if let match = extractText(from: item) {
                    return match
                }
            }
        }
        return nil
    }

    private func transcript<S: Sequence>(for messages: S) -> String where S.Element == TelegramThreadMessage {
        messages
            .sorted(by: { $0.date < $1.date })
            .map { "\($0.author): \($0.text)" }
            .joined(separator: "\n")
    }
}
