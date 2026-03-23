import Foundation

struct TelegramBotProfile: Decodable {
    let id: Int64
    let firstName: String
    let username: String?
    let canJoinGroups: Bool?
    let canReadAllGroupMessages: Bool?
    let supportsInlineQueries: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case username
        case canJoinGroups = "can_join_groups"
        case canReadAllGroupMessages = "can_read_all_group_messages"
        case supportsInlineQueries = "supports_inline_queries"
    }

    var displayName: String {
        if let username, !username.isEmpty {
            return "@\(username)"
        }
        return firstName
    }

    var safeUsername: String? {
        guard let username, !username.isEmpty else { return nil }
        return username
    }
}

enum TelegramChatKind: String, Codable {
    case privateChat = "private"
    case group
    case supergroup
    case channel
    case unknown

    init(rawType: String) {
        self = TelegramChatKind(rawValue: rawType) ?? .unknown
    }

    var title: String {
        switch self {
        case .privateChat: return "Private"
        case .group: return "Group"
        case .supergroup: return "Supergroup"
        case .channel: return "Channel"
        case .unknown: return "Chat"
        }
    }

    var symbolName: String {
        switch self {
        case .privateChat: return "person.fill"
        case .group, .supergroup: return "person.3.fill"
        case .channel: return "megaphone.fill"
        case .unknown: return "message.fill"
        }
    }
}

struct TelegramThreadMessage: Identifiable, Codable, Hashable {
    let id: Int64
    let author: String
    let text: String
    let date: Date
    let isOutgoing: Bool
}

struct TelegramThread: Identifiable, Codable, Hashable {
    let chatID: Int64
    let title: String
    let username: String?
    let kind: TelegramChatKind
    var latestText: String
    var latestDate: Date
    var recentCount: Int
    var messages: [TelegramThreadMessage]

    var id: Int64 { chatID }
}

struct TelegramInboxSnapshot {
    let bot: TelegramBotProfile
    let threads: [TelegramThread]
}
