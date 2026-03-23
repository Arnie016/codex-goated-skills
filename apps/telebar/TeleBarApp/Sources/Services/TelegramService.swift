import Foundation

struct TelegramService {
    enum ServiceError: LocalizedError {
        case invalidURL
        case invalidResponse
        case api(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The Telegram URL could not be created."
            case .invalidResponse:
                return "Telegram returned an unreadable response."
            case .api(let description):
                return description
            }
        }
    }

    func fetchInbox(botToken: String) async throws -> TelegramInboxSnapshot {
        let bot: TelegramBotProfile = try await request(method: "getMe", token: botToken, payload: nil)
        let updates: [TelegramUpdateEnvelope] = try await request(
            method: "getUpdates",
            token: botToken,
            payload: [
                "limit": 60,
                "allowed_updates": [
                    "message",
                    "edited_message",
                    "channel_post",
                    "edited_channel_post"
                ]
            ]
        )
        let threads = buildThreads(from: updates, bot: bot)
        return TelegramInboxSnapshot(bot: bot, threads: threads)
    }

    func sendMessage(botToken: String, chatID: Int64, text: String) async throws {
        let payload: [String: Any] = [
            "chat_id": String(chatID),
            "text": text,
            "disable_web_page_preview": true
        ]
        let _: TelegramMessageEnvelope = try await request(method: "sendMessage", token: botToken, payload: payload)
    }

    private func request<T: Decodable>(
        method: String,
        token: String,
        payload: [String: Any]?
    ) async throws -> T {
        guard let url = URL(string: "https://api.telegram.org/bot\(token)/\(method)") else {
            throw ServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let payload {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ServiceError.invalidResponse
        }

        let envelope = try JSONDecoder().decode(TelegramEnvelope<T>.self, from: data)
        guard envelope.ok else {
            throw ServiceError.api(envelope.description ?? "Telegram rejected the request.")
        }
        guard let result = envelope.result else {
            throw ServiceError.invalidResponse
        }
        return result
    }

    private func buildThreads(from updates: [TelegramUpdateEnvelope], bot: TelegramBotProfile) -> [TelegramThread] {
        let events = updates.compactMap(\.eventMessage)
        var grouped: [Int64: TelegramThread] = [:]

        for message in events.sorted(by: { $0.date > $1.date }) {
            let chatID = message.chat.id
            let date = Date(timeIntervalSince1970: TimeInterval(message.date))
            let author = resolveAuthor(for: message, bot: bot)
            let text = resolvedText(for: message)
            let chatKind = TelegramChatKind(rawType: message.chat.type)
            let title = resolveTitle(for: message)
            let threadMessage = TelegramThreadMessage(
                id: Int64(message.messageID),
                author: author,
                text: text,
                date: date,
                isOutgoing: (message.from?.isBot ?? false) || author == bot.firstName
            )

            if var existing = grouped[chatID] {
                existing.recentCount += 1
                existing.messages.append(threadMessage)
                existing.messages.sort(by: { $0.date > $1.date })
                if date > existing.latestDate {
                    existing.latestDate = date
                    existing.latestText = text
                }
                grouped[chatID] = existing
            } else {
                grouped[chatID] = TelegramThread(
                    chatID: chatID,
                    title: title,
                    username: message.chat.username,
                    kind: chatKind,
                    latestText: text,
                    latestDate: date,
                    recentCount: 1,
                    messages: [threadMessage]
                )
            }
        }

        return grouped.values.sorted(by: { $0.latestDate > $1.latestDate })
    }

    private func resolveTitle(for message: TelegramMessageEnvelope) -> String {
        let chat = message.chat
        if let title = chat.title, !title.isEmpty {
            return title
        }
        let first = chat.firstName ?? message.from?.firstName ?? message.senderChat?.title ?? "Telegram"
        let last = chat.lastName ?? message.from?.lastName ?? ""
        let joined = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)
        if !joined.isEmpty {
            return joined
        }
        if let username = chat.username {
            return "@\(username)"
        }
        return "Chat \(chat.id)"
    }

    private func resolveAuthor(for message: TelegramMessageEnvelope, bot: TelegramBotProfile) -> String {
        if let senderChatTitle = message.senderChat?.title, !senderChatTitle.isEmpty {
            return senderChatTitle
        }
        if let from = message.from {
            let name = "\(from.firstName ?? "") \(from.lastName ?? "")"
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                return name
            }
            if let username = from.username, !username.isEmpty {
                return "@\(username)"
            }
            if from.isBot {
                return bot.firstName
            }
        }
        return "Unknown"
    }

    private func resolvedText(for message: TelegramMessageEnvelope) -> String {
        let raw = message.text ?? message.caption ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "[Non-text message]" : trimmed
    }
}

private struct TelegramEnvelope<T: Decodable>: Decodable {
    let ok: Bool
    let result: T?
    let description: String?
}

private struct TelegramUpdateEnvelope: Decodable {
    let updateID: Int64
    let message: TelegramMessageEnvelope?
    let editedMessage: TelegramMessageEnvelope?
    let channelPost: TelegramMessageEnvelope?
    let editedChannelPost: TelegramMessageEnvelope?

    enum CodingKeys: String, CodingKey {
        case updateID = "update_id"
        case message
        case editedMessage = "edited_message"
        case channelPost = "channel_post"
        case editedChannelPost = "edited_channel_post"
    }

    var eventMessage: TelegramMessageEnvelope? {
        message ?? editedMessage ?? channelPost ?? editedChannelPost
    }
}

private struct TelegramMessageEnvelope: Decodable {
    let messageID: Int
    let date: Int
    let text: String?
    let caption: String?
    let from: TelegramUserEnvelope?
    let senderChat: TelegramChatEnvelope?
    let chat: TelegramChatEnvelope

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case date
        case text
        case caption
        case from
        case senderChat = "sender_chat"
        case chat
    }
}

private struct TelegramUserEnvelope: Decodable {
    let firstName: String?
    let lastName: String?
    let username: String?
    let isBot: Bool

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case username
        case isBot = "is_bot"
    }
}

private struct TelegramChatEnvelope: Decodable {
    let id: Int64
    let type: String
    let title: String?
    let username: String?
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case username
        case firstName = "first_name"
        case lastName = "last_name"
    }
}
