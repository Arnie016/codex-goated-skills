import AppKit
import Combine
import SwiftUI

@main
struct ClipboardLinkBarApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = StatusController()
    }
}

struct ClipboardEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let copiedAt: Date
    let sourceApp: String
    var researchNote: String

    var url: URL? {
        URLDetector.firstURL(in: text)
    }

    var isLink: Bool {
        url != nil
    }

    var title: String {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url {
            return url.host ?? url.absoluteString
        }
        return normalized.isEmpty ? "Clipboard text" : normalized
    }

    var subtitle: String {
        if let url {
            let path = url.path.isEmpty ? "/" : url.path
            return "\(url.scheme ?? "link")://\(url.host ?? "local")\(path)"
        }
        return "\(text.count) characters"
    }

    var localContext: String {
        if let url {
            let host = url.host ?? "unknown host"
            let queryCount = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.count ?? 0
            let path = url.pathComponents.filter { $0 != "/" }.joined(separator: " / ")
            let route = path.isEmpty ? "home page" : path
            let query = queryCount == 0 ? "no query parameters" : "\(queryCount) query parameters"
            return "Copied from \(sourceApp). Looks like \(host), route: \(route), with \(query)."
        }
        return "Copied from \(sourceApp). Plain text, \(text.count) characters."
    }
}

enum URLDetector {
    static func firstURL(in text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector?.firstMatch(in: text, range: range)?.url
    }
}

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var entries: [ClipboardEntry] = []
    @Published var selectedID: UUID?
    @Published var filterText = ""
    @Published private(set) var statusText = "Watching clipboard"
    @Published private(set) var isResearching = false

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let maxEntries = 18

    init() {
        lastChangeCount = pasteboard.changeCount
        start()
        captureCurrentPasteboard()
    }

    var filteredEntries: [ClipboardEntry] {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return entries }
        return entries.filter { entry in
            entry.text.lowercased().contains(query) ||
                entry.sourceApp.lowercased().contains(query) ||
                entry.subtitle.lowercased().contains(query)
        }
    }

    var selectedEntry: ClipboardEntry? {
        if let selectedID,
           let match = entries.first(where: { $0.id == selectedID }) {
            return match
        }
        return filteredEntries.first
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPasteboard()
            }
        }
    }

    func clear() {
        entries.removeAll()
        selectedID = nil
        statusText = "History cleared"
    }

    func copy(_ entry: ClipboardEntry) {
        pasteboard.clearContents()
        pasteboard.setString(entry.text, forType: .string)
        lastChangeCount = pasteboard.changeCount
        statusText = "Copied item back to clipboard"
    }

    func open(_ entry: ClipboardEntry) {
        guard let url = entry.url else { return }
        NSWorkspace.shared.open(url)
        statusText = "Opened \(url.host ?? "link")"
    }

    func research(_ entry: ClipboardEntry) {
        guard let url = entry.url else {
            updateResearch("No URL to research.", for: entry.id)
            return
        }

        isResearching = true
        statusText = "Researching \(url.host ?? "link")"

        Task {
            let note = await LinkResearcher.research(url: url)
            await MainActor.run {
                self.updateResearch(note, for: entry.id)
                self.isResearching = false
                self.statusText = "Research ready"
            }
        }
    }

    private func pollPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        captureCurrentPasteboard()
    }

    private func captureCurrentPasteboard() {
        guard let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              !looksSensitive(text) else {
            return
        }

        if entries.first?.text == text {
            return
        }

        let entry = ClipboardEntry(
            id: UUID(),
            text: text,
            copiedAt: Date(),
            sourceApp: NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown app",
            researchNote: ""
        )

        entries.removeAll { $0.text == text }
        entries.insert(entry, at: 0)
        entries = Array(entries.prefix(maxEntries))
        selectedID = entry.id
        statusText = entry.isLink ? "Captured link" : "Captured text"
    }

    private func updateResearch(_ note: String, for id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].researchNote = note
    }

    private func looksSensitive(_ text: String) -> Bool {
        let lower = text.lowercased()
        let markers = ["password", "passwd", "api_key", "apikey", "secret", "token", "bearer ", "sk-"]
        if markers.contains(where: { lower.contains($0) }) {
            statusText = "Skipped sensitive-looking clipboard item"
            return true
        }
        return false
    }
}

enum LinkResearcher {
    static func research(url: URL) async -> String {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("ClipboardLinkBar/0.1", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let html = String(decoding: data.prefix(180_000), as: UTF8.self)
            let title = firstMatch(#"<title[^>]*>(.*?)</title>"#, in: html)
                .map(cleanHTMLText) ?? "No title found"
            let description = firstMatch(#"<meta\s+[^>]*(?:name|property)=["'](?:description|og:description)["'][^>]*content=["']([^"']+)["'][^>]*>"#, in: html)
                .map(cleanHTMLText)

            if let description, !description.isEmpty {
                return "HTTP \(status). \(title). \(description)"
            }
            return "HTTP \(status). \(title)."
        } catch {
            return "Research failed: \(error.localizedDescription)"
        }
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captureRange])
    }

    private static func cleanHTMLText(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
enum ClipboardIconRenderer {
    static func image(count: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 16))
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: 18, height: 16).fill()

        NSColor(calibratedRed: 0.05, green: 0.45, blue: 0.62, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 2.2, y: 1.6, width: 13.6, height: 12.4), xRadius: 3.2, yRadius: 3.2).fill()

        NSColor.white.withAlphaComponent(0.92).setStroke()
        let link = NSBezierPath()
        link.lineWidth = 1.7
        link.lineCapStyle = .round
        link.move(to: NSPoint(x: 6.0, y: 8.4))
        link.line(to: NSPoint(x: 8.1, y: 10.5))
        link.move(to: NSPoint(x: 9.8, y: 5.8))
        link.line(to: NSPoint(x: 12.0, y: 8.0))
        link.stroke()

        NSColor.white.setFill()
        let dotCount = min(3, max(0, count))
        for index in 0..<dotCount {
            NSBezierPath(ovalIn: NSRect(x: 5.0 + CGFloat(index * 3), y: 3.8, width: 1.5, height: 1.5)).fill()
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

@MainActor
final class StatusController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let store = ClipboardStore()

    override init() {
        super.init()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 760, height: 560)
        popover.contentViewController = NSHostingController(rootView: ClipboardPanel(store: store))

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.imagePosition = .imageLeading
        }

        store.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }.store(in: &cancellables)

        updateStatusItem()
    }

    private var cancellables: Set<AnyCancellable> = []

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = ClipboardIconRenderer.image(count: store.entries.count)
        button.attributedTitle = NSAttributedString(
            string: store.entries.isEmpty ? "" : " \(store.entries.count)",
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
        )
        button.contentTintColor = nil
        button.toolTip = "Clipboard links: \(store.entries.count)"
    }
}

struct ClipboardPanel: View {
    @ObservedObject var store: ClipboardStore

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HStack(spacing: 0) {
                list
                    .frame(width: 300)
                Divider()
                detail
            }
        }
        .frame(width: 760, height: 560)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Image(nsImage: ClipboardIconRenderer.image(count: store.entries.count))
            TextField("Filter clipboard history", text: $store.filterText)
                .textFieldStyle(.roundedBorder)
            Button {
                store.clear()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Clear local clipboard history")
        }
        .padding(12)
    }

    private var list: some View {
        List(selection: $store.selectedID) {
            ForEach(store.filteredEntries) { entry in
                HStack(spacing: 9) {
                    Image(systemName: entry.isLink ? "link" : "doc.text")
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Text(entry.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .tag(entry.id)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if store.filteredEntries.isEmpty {
                Text("Copy a link or text")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let entry = store.selectedEntry {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.system(size: 18, weight: .bold))
                            .lineLimit(2)
                        Text(entry.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button {
                        store.copy(entry)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .help("Copy this item again")

                    if entry.isLink {
                        Button {
                            store.open(entry)
                        } label: {
                            Image(systemName: "arrow.up.forward.app")
                        }
                        .help("Open link")
                    }
                }

                Text(entry.text)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                contextBlock(title: "Context", text: entry.localContext)

                HStack {
                    Text("Research")
                        .font(.headline)
                    Spacer()
                    Button {
                        store.research(entry)
                    } label: {
                        if store.isResearching {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    .disabled(!entry.isLink || store.isResearching)
                    .help("Research this URL")
                }

                contextBlock(title: "Result", text: entry.researchNote.isEmpty ? "Select a link and press Research." : entry.researchNote)

                Spacer()
                Text(store.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Spacer()
                Text("Recent clipboard links appear here")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(16)
    }

    private func contextBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
