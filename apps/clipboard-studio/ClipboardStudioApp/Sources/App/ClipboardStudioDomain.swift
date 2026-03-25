import Foundation

struct ClipboardEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
    let sourceAppName: String?
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        sourceAppName: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.sourceAppName = sourceAppName
        self.isPinned = isPinned
    }

    var title: String {
        let compact = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !compact.isEmpty else { return "Untitled Clip" }
        return String(compact.prefix(78))
    }
}

struct ClipboardHistoryStore: Codable, Equatable {
    var entries: [ClipboardEntry] = []

    mutating func record(text: String, sourceAppName: String?, limit: Int) -> ClipboardEntry {
        if let existingIndex = entries.firstIndex(where: { $0.text == text }) {
            var existing = entries.remove(at: existingIndex)
            existing = ClipboardEntry(
                id: existing.id,
                text: existing.text,
                createdAt: Date(),
                sourceAppName: sourceAppName ?? existing.sourceAppName,
                isPinned: existing.isPinned
            )
            entries.insert(existing, at: 0)
            return existing
        }

        let entry = ClipboardEntry(text: text, sourceAppName: sourceAppName)
        entries.insert(entry, at: 0)
        if entries.count > limit {
            entries = Array(entries.prefix(limit))
        }
        return entry
    }

    mutating func togglePin(id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].isPinned.toggle()
    }

    mutating func clear() {
        entries.removeAll()
    }

    func filtered(matching query: String) -> [ClipboardEntry] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return entries }

        return entries.filter { entry in
            entry.text.localizedCaseInsensitiveContains(trimmedQuery) ||
            (entry.sourceAppName?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
        }
    }
}

struct PackItem: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let sourceAppName: String?
    let capturedAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        sourceAppName: String? = nil,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.sourceAppName = sourceAppName
        self.capturedAt = capturedAt
    }

    var title: String {
        let compact = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !compact.isEmpty else { return "Empty Context" }
        return String(compact.prefix(72))
    }

    var previewLine: String {
        let firstLine = text
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !firstLine.isEmpty else { return title }
        return String(firstLine.prefix(96))
    }
}

struct ContextPack: Codable, Equatable {
    enum InsertResult: Equatable {
        case added(PackItem)
        case duplicate(PackItem)
    }

    var items: [PackItem] = []

    var isEmpty: Bool {
        items.isEmpty
    }

    var count: Int {
        items.count
    }

    mutating func insert(text: String, sourceAppName: String?) -> InsertResult {
        if let existing = items.first(where: { $0.text == text }) {
            return .duplicate(existing)
        }

        let item = PackItem(text: text, sourceAppName: sourceAppName)
        items.insert(item, at: 0)
        return .added(item)
    }

    mutating func insert(entry: ClipboardEntry) -> InsertResult {
        insert(text: entry.text, sourceAppName: entry.sourceAppName)
    }

    @discardableResult
    mutating func remove(id: UUID) -> PackItem? {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        return items.remove(at: index)
    }

    mutating func clear() {
        items.removeAll()
    }
}

struct LastSendResult: Equatable {
    enum Delivery: String, Equatable {
        case directSend
        case clipboardFallback
    }

    let delivery: Delivery
    let targetAppName: String?
    let detail: String
    let timestamp: Date

    var label: String {
        switch delivery {
        case .directSend:
            return "Direct Send"
        case .clipboardFallback:
            return "Clipboard Fallback"
        }
    }
}

struct PackToastState: Equatable {
    enum Kind: Equatable {
        case capture
        case duplicate
        case directSend
        case fallback
        case error
    }

    let kind: Kind
    let title: String
    let detail: String
    let preview: String
    let sourceAppName: String?
    let packCount: Int
    let undoItemID: UUID?
    let autoDismissAfter: TimeInterval?
}

enum ClipboardStudioShortcut: CaseIterable {
    case captureSelection
    case sendPack
    case openPack

    var title: String {
        switch self {
        case .captureSelection:
            return "Capture"
        case .sendPack:
            return "Send"
        case .openPack:
            return "Pack"
        }
    }

    var keyChord: String {
        switch self {
        case .captureSelection:
            return "⌃⌥C"
        case .sendPack:
            return "⌃⌥V"
        case .openPack:
            return "⌃⌥P"
        }
    }

    var helpText: String {
        switch self {
        case .captureSelection:
            return "Capture the selected text into the active pack."
        case .sendPack:
            return "Send the active prompt pack to the last app you were working in."
        case .openPack:
            return "Open the floating pack editor."
        }
    }
}
