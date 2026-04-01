import Foundation

enum ContextAssemblyBrand {
    static let appName = "Context Assembly"
    static let defaultExportStem = "context-assembly"
}

struct FocusSnapshot: Identifiable, Codable, Equatable {
    let id: UUID
    let appName: String
    let bundleIdentifier: String?
    let windowTitle: String?
    let pageTitle: String?
    let urlString: String?
    let selectedText: String?
    let capturedAt: Date

    init(
        id: UUID = UUID(),
        appName: String,
        bundleIdentifier: String? = nil,
        windowTitle: String? = nil,
        pageTitle: String? = nil,
        urlString: String? = nil,
        selectedText: String? = nil,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.windowTitle = windowTitle
        self.pageTitle = pageTitle
        self.urlString = urlString
        self.selectedText = selectedText
        self.capturedAt = capturedAt
    }

    var sourceLabel: String {
        let trimmed = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unknown App" : trimmed
    }

    var hasSelectedText: Bool {
        !(selectedText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var primaryTitle: String {
        if let pageTitle = trimmed(pageTitle) {
            return pageTitle
        }
        if let windowTitle = trimmed(windowTitle) {
            return windowTitle
        }
        if let selectedTitle = trimmed(selectedText)?
            .replacingOccurrences(of: "\n", with: " ") {
            return String(selectedTitle.prefix(82))
        }
        return sourceLabel
    }

    var detailLine: String? {
        if let prettyURL {
            return prettyURL
        }
        if let windowTitle = trimmed(windowTitle), windowTitle != primaryTitle {
            return windowTitle
        }
        if hasSelectedText {
            return "Selected text is ready to add, merge, or copy."
        }
        return nil
    }

    var selectionPreview: String? {
        guard let selectedText = trimmed(selectedText) else { return nil }
        return String(selectedText.prefix(220))
    }

    var statusLabel: String {
        if hasSelectedText {
            return "Selection Ready"
        }
        if urlString != nil {
            return "Page Ready"
        }
        return "State Ready"
    }

    var resumeLabel: String {
        urlString != nil ? "Resume Page" : "Resume App"
    }

    var prettyURL: String? {
        guard let urlString = trimmed(urlString),
              let url = URL(string: urlString) else {
            return nil
        }

        var visible = url.host(percentEncoded: false) ?? url.host() ?? urlString
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !path.isEmpty {
            visible += "/\(path)"
        }
        if let query = url.query, !query.isEmpty {
            visible += "?\(query)"
        }
        if visible.count > 56 {
            return String(visible.prefix(53)) + "..."
        }
        return visible
    }

    var assemblyText: String {
        var lines = ["Source App: \(sourceLabel)"]

        if let pageTitle = trimmed(pageTitle) {
            lines.append("Page Title: \(pageTitle)")
        } else if let windowTitle = trimmed(windowTitle) {
            lines.append("Window Title: \(windowTitle)")
        }

        if let urlString = trimmed(urlString) {
            lines.append("URL: \(urlString)")
        }

        if let selectedText = trimmed(selectedText) {
            lines.append("Selected Text:")
            lines.append(selectedText)
        } else if let detailLine {
            lines.append("Current State: \(detailLine)")
        }

        return lines.joined(separator: "\n")
    }

    var signature: String {
        [
            bundleIdentifier ?? sourceLabel,
            trimmed(pageTitle) ?? "",
            trimmed(windowTitle) ?? "",
            trimmed(urlString) ?? "",
            String((trimmed(selectedText) ?? "").prefix(180))
        ]
        .joined(separator: "|")
    }

    private func trimmed(_ value: String?) -> String? {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}

struct FocusHistoryStore: Codable, Equatable {
    var items: [FocusSnapshot] = []

    mutating func record(snapshot: FocusSnapshot, limit: Int) -> FocusSnapshot {
        if let existingIndex = items.firstIndex(where: { $0.signature == snapshot.signature }) {
            let existing = items.remove(at: existingIndex)
            let refreshed = FocusSnapshot(
                id: existing.id,
                appName: snapshot.appName,
                bundleIdentifier: snapshot.bundleIdentifier,
                windowTitle: snapshot.windowTitle,
                pageTitle: snapshot.pageTitle,
                urlString: snapshot.urlString,
                selectedText: snapshot.selectedText,
                capturedAt: snapshot.capturedAt
            )
            items.insert(refreshed, at: 0)
            return refreshed
        }

        items.insert(snapshot, at: 0)
        if items.count > limit {
            items = Array(items.prefix(limit))
        }
        return snapshot
    }

    mutating func clear() {
        items.removeAll()
    }

    func filtered(matching query: String) -> [FocusSnapshot] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return items }

        return items.filter { snapshot in
            snapshot.appName.localizedCaseInsensitiveContains(trimmedQuery) ||
            (snapshot.windowTitle?.localizedCaseInsensitiveContains(trimmedQuery) ?? false) ||
            (snapshot.pageTitle?.localizedCaseInsensitiveContains(trimmedQuery) ?? false) ||
            (snapshot.urlString?.localizedCaseInsensitiveContains(trimmedQuery) ?? false) ||
            (snapshot.selectedText?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
        }
    }
}

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
        guard !compact.isEmpty else { return "Untitled Capture" }
        return String(compact.prefix(78))
    }

    var sourceLabel: String {
        let trimmedSource = sourceAppName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedSource.isEmpty ? "Unknown App" : trimmedSource
    }
}

struct ClipboardHistoryStore: Codable, Equatable {
    var entries: [ClipboardEntry] = []

    mutating func record(
        text: String,
        sourceAppName: String?,
        limit: Int,
        createdAt: Date = Date()
    ) -> ClipboardEntry {
        if let existingIndex = entries.firstIndex(where: { $0.text == text }) {
            var existing = entries.remove(at: existingIndex)
            existing = ClipboardEntry(
                id: existing.id,
                text: existing.text,
                createdAt: createdAt,
                sourceAppName: sourceAppName ?? existing.sourceAppName,
                isPinned: existing.isPinned
            )
            entries.insert(existing, at: 0)
            return existing
        }

        let entry = ClipboardEntry(text: text, createdAt: createdAt, sourceAppName: sourceAppName)
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

    var sourceLabel: String {
        let trimmedSource = sourceAppName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedSource.isEmpty ? "Unknown App" : trimmedSource
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

    var timelineItems: [PackItem] {
        Array(items.reversed())
    }

    func timelineStep(for id: UUID) -> Int? {
        timelineItems.firstIndex(where: { $0.id == id }).map { $0 + 1 }
    }

    mutating func insert(
        text: String,
        sourceAppName: String?,
        capturedAt: Date = Date()
    ) -> InsertResult {
        if let existing = items.first(where: { $0.text == text }) {
            return .duplicate(existing)
        }

        let item = PackItem(text: text, sourceAppName: sourceAppName, capturedAt: capturedAt)
        items.insert(item, at: 0)
        return .added(item)
    }

    mutating func insert(entry: ClipboardEntry, capturedAt: Date = Date()) -> InsertResult {
        insert(text: entry.text, sourceAppName: entry.sourceAppName, capturedAt: capturedAt)
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
            return "Paste"
        case .openPack:
            return "Window"
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
            return "Capture the selection and start the assembly timeline if needed."
        case .sendPack:
            return "Paste the active assembly into the app you were just using."
        case .openPack:
            return "Open or close the floating assembly window."
        }
    }
}
