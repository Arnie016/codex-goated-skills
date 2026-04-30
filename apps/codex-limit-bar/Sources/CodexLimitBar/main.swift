import AppKit
import SwiftUI

enum AppTheme {
    static let primary = Color(red: 0.16, green: 0.33, blue: 0.62)
    static let short = Color(red: 0.09, green: 0.44, blue: 0.58)
    static let weekly = Color(red: 0.39, green: 0.34, blue: 0.66)
    static let amber = Color(red: 0.78, green: 0.49, blue: 0.12)
    static let red = Color(red: 0.74, green: 0.18, blue: 0.18)
    static let window = Color(nsColor: .windowBackgroundColor)
    static let panel = Color(nsColor: .controlBackgroundColor)
    static let card = Color(nsColor: .textBackgroundColor)
    static let border = Color(nsColor: .separatorColor).opacity(0.55)

    static func statusColor(forUsed value: Double) -> Color {
        switch value {
        case 80...:
            return red
        case 50...:
            return amber
        default:
            return primary
        }
    }

    static func statusNSColor(forUsed value: Double) -> NSColor {
        switch value {
        case 80...:
            return NSColor(calibratedRed: 0.74, green: 0.18, blue: 0.18, alpha: 1)
        case 50...:
            return NSColor(calibratedRed: 0.78, green: 0.49, blue: 0.12, alpha: 1)
        default:
            return NSColor(calibratedRed: 0.16, green: 0.33, blue: 0.62, alpha: 1)
        }
    }
}

@MainActor
final class LimitStore: ObservableObject {
    private enum Keys {
        static let shortUsed = "shortUsed"
        static let weeklyUsed = "weeklyUsed"
        static let legacyShortRemaining = "shortRemaining"
        static let legacyWeeklyRemaining = "weeklyRemaining"
        static let shortResetText = "shortResetText"
        static let weeklyResetText = "weeklyResetText"
        static let pasteText = "pasteText"
    }

    private let defaults = UserDefaults.standard
    var onChange: (() -> Void)?

    @Published var shortUsed: Double {
        didSet {
            let normalized = clamp(shortUsed)
            guard normalized == shortUsed else {
                Task { @MainActor in
                    self.shortUsed = normalized
                }
                return
            }
            defaults.set(shortUsed, forKey: Keys.shortUsed)
            onChange?()
        }
    }

    @Published var weeklyUsed: Double {
        didSet {
            let normalized = clamp(weeklyUsed)
            guard normalized == weeklyUsed else {
                Task { @MainActor in
                    self.weeklyUsed = normalized
                }
                return
            }
            defaults.set(weeklyUsed, forKey: Keys.weeklyUsed)
            onChange?()
        }
    }

    @Published var shortResetText: String {
        didSet {
            defaults.set(shortResetText, forKey: Keys.shortResetText)
            onChange?()
        }
    }

    @Published var weeklyResetText: String {
        didSet {
            defaults.set(weeklyResetText, forKey: Keys.weeklyResetText)
            onChange?()
        }
    }

    @Published var pasteText: String {
        didSet {
            defaults.set(pasteText, forKey: Keys.pasteText)
        }
    }

    @Published var isRefreshing = false
    @Published var refreshState = "Manual snapshot"
    @Published var lastUpdatedText = "Not refreshed"

    init() {
        let savedShortUsed = defaults.object(forKey: Keys.shortUsed) as? Double
        let savedWeeklyUsed = defaults.object(forKey: Keys.weeklyUsed) as? Double
        let legacyShortRemaining = defaults.object(forKey: Keys.legacyShortRemaining) as? Double
        let legacyWeeklyRemaining = defaults.object(forKey: Keys.legacyWeeklyRemaining) as? Double

        shortUsed = savedShortUsed ?? legacyShortRemaining.map { 100 - $0 } ?? 21
        weeklyUsed = savedWeeklyUsed ?? legacyWeeklyRemaining.map { 100 - $0 } ?? 13
        shortResetText = defaults.string(forKey: Keys.shortResetText) ?? "04:42"
        weeklyResetText = defaults.string(forKey: Keys.weeklyResetText) ?? "5 May"
        pasteText = defaults.string(forKey: Keys.pasteText) ?? "5h 79% 04:42\nWeekly 87% 5 May"
    }

    var shortRemaining: Double {
        100 - shortUsed
    }

    var weeklyRemaining: Double {
        100 - weeklyUsed
    }

    var highestUsed: Double {
        max(shortUsed, weeklyUsed)
    }

    var limitingWindowTitle: String {
        shortUsed >= weeklyUsed ? "5-hour window" : "Weekly"
    }

    var sourceText: String {
        refreshState == "Live" ? "Live" : refreshState
    }

    var statusTitle: String {
        switch highestUsed {
        case 80...:
            return "Tight"
        case 50...:
            return "Watch"
        default:
            return "Healthy"
        }
    }

    var statusDetail: String {
        "\(limitingWindowTitle) has the most usage. If either bucket reaches 100%, Codex pauses until that bucket refreshes."
    }

    func applyScreenshotValues() {
        shortUsed = 21
        weeklyUsed = 13
        shortResetText = "04:42"
        weeklyResetText = "5 May"
        pasteText = "5h 79% 04:42\nWeekly 87% 5 May"
        refreshState = "Manual snapshot"
        lastUpdatedText = "From screenshot"
    }

    @discardableResult
    func applyPastedStatus() -> Bool {
        let percents = regexMatches(#"(\d{1,3})\s*%"#, in: pasteText).compactMap { Double($0) }
        if percents.count >= 2 {
            shortUsed = 100 - clamp(percents[0])
            weeklyUsed = 100 - clamp(percents[1])
        }

        if let time = regexFirst(#"\b\d{1,2}:\d{2}\b"#, in: pasteText) {
            shortResetText = time
        }

        if let date = regexFirst(#"\b\d{1,2}\s+[A-Za-z]{3,9}\b"#, in: pasteText) {
            weeklyResetText = date
        }

        if percents.count >= 2 {
            refreshState = "Manual snapshot"
            lastUpdatedText = "Parsed pasted text"
        }

        return percents.count >= 2
    }

    func refreshFromCodex() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        refreshState = "Refreshing"

        do {
            let snapshot = try await CodexRateLimitClient.fetch()
            shortUsed = snapshot.shortUsed
            weeklyUsed = snapshot.weeklyUsed
            shortResetText = formatReset(snapshot.shortResetsAt, fallback: shortResetText)
            weeklyResetText = formatReset(snapshot.weeklyResetsAt, fallback: weeklyResetText)
            refreshState = "Live"
            lastUpdatedText = Self.timeFormatter.string(from: Date())
        } catch {
            refreshState = "Refresh failed"
            lastUpdatedText = error.localizedDescription
        }

        isRefreshing = false
        onChange?()
    }

    private func clamp(_ value: Double) -> Double {
        min(100, max(0, value))
    }

    private func formatReset(_ epochSeconds: Int?, fallback: String) -> String {
        guard let epochSeconds else {
            return fallback
        }

        let resetDate = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        let remaining = resetDate.timeIntervalSinceNow
        if remaining > 0 && remaining < 24 * 60 * 60 {
            let totalMinutes = max(1, Int(remaining / 60))
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return hours > 0 ? "in \(hours)h \(minutes)m" : "in \(minutes)m"
        }

        return Self.dateFormatter.string(from: resetDate)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private func regexMatches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let captureRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[captureRange])
        }
    }

    private func regexFirst(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let matchRange = Range(match.range, in: text) else {
            return nil
        }

        return String(text[matchRange])
    }
}

struct LiveRateLimitSnapshot {
    let shortUsed: Double
    let weeklyUsed: Double
    let shortResetsAt: Int?
    let weeklyResetsAt: Int?
}

enum CodexRateLimitClient {
    enum ClientError: LocalizedError {
        case codexNotFound
        case timedOut
        case server(String)
        case malformedResponse

        var errorDescription: String? {
            switch self {
            case .codexNotFound:
                return "Codex CLI not found"
            case .timedOut:
                return "Refresh timed out"
            case .server(let message):
                return message
            case .malformedResponse:
                return "Unexpected rate-limit response"
            }
        }
    }

    static func fetch(timeout: TimeInterval = 20) async throws -> LiveRateLimitSnapshot {
        try await Task.detached(priority: .utility) {
            try fetchSynchronously(timeout: timeout)
        }.value
    }

    private static func fetchSynchronously(timeout: TimeInterval) throws -> LiveRateLimitSnapshot {
        let process = Process()
        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        let semaphore = DispatchSemaphore(value: 0)
        let capture = ResponseCapture(semaphore: semaphore)

        configure(process)
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        stdout.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else {
                return
            }

            capture.append(chunk)
        }

        process.terminationHandler = { _ in
            capture.failIfNeeded(ClientError.malformedResponse)
        }

        try process.run()

        let messages = [
            #"{"id":1,"method":"initialize","params":{"clientInfo":{"name":"CodexLimitBar","version":"0.1.0"}}}"#,
            #"{"method":"initialized"}"#,
            #"{"id":2,"method":"account/rateLimits/read","params":null}"#
        ].joined(separator: "\n") + "\n"

        stdin.fileHandleForWriting.write(Data(messages.utf8))

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            cleanup(process: process, stdout: stdout, stderr: stderr)
            throw ClientError.timedOut
        }

        cleanup(process: process, stdout: stdout, stderr: stderr)

        guard let result = capture.result else {
            throw ClientError.malformedResponse
        }

        return try result.get()
    }

    private final class ResponseCapture: @unchecked Sendable {
        private let lock = NSLock()
        private let semaphore: DispatchSemaphore
        private var buffer = ""
        private var storedResult: Result<LiveRateLimitSnapshot, Error>?

        init(semaphore: DispatchSemaphore) {
            self.semaphore = semaphore
        }

        var result: Result<LiveRateLimitSnapshot, Error>? {
            lock.lock()
            defer { lock.unlock() }
            return storedResult
        }

        func append(_ chunk: String) {
            lock.lock()
            defer { lock.unlock() }

            buffer += chunk
            while let newline = buffer.firstIndex(of: "\n") {
                let line = String(buffer[..<newline]).trimmingCharacters(in: .whitespacesAndNewlines)
                buffer.removeSubrange(...newline)
                if storedResult == nil, let parsed = parseLine(line) {
                    storedResult = parsed
                    semaphore.signal()
                }
            }
        }

        func failIfNeeded(_ error: Error) {
            lock.lock()
            defer { lock.unlock() }

            if storedResult == nil {
                storedResult = .failure(error)
                semaphore.signal()
            }
        }
    }

    private static func configure(_ process: Process) {
        let fileManager = FileManager.default
        let knownPaths = ["/opt/homebrew/bin/codex", "/usr/local/bin/codex"]

        if let path = knownPaths.first(where: { fileManager.isExecutableFile(atPath: $0) }) {
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = ["app-server", "--listen", "stdio://"]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["codex", "app-server", "--listen", "stdio://"]
        }
    }

    private static func cleanup(process: Process, stdout: Pipe, stderr: Pipe) {
        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil
        if process.isRunning {
            process.terminate()
        }
    }

    private static func parseLine(_ line: String) -> Result<LiveRateLimitSnapshot, Error>? {
        guard !line.isEmpty,
              let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = object["id"] as? Int,
              id == 2 else {
            return nil
        }

        if let error = object["error"] as? [String: Any] {
            return .failure(ClientError.server(error["message"] as? String ?? "Codex refresh failed"))
        }

        guard let result = object["result"] as? [String: Any] else {
            return .failure(ClientError.malformedResponse)
        }

        do {
            return .success(try parseSnapshot(from: result))
        } catch {
            return .failure(error)
        }
    }

    private static func parseSnapshot(from result: [String: Any]) throws -> LiveRateLimitSnapshot {
        let byLimitId = result["rateLimitsByLimitId"] as? [String: Any]
        let snapshot = byLimitId?["codex"] as? [String: Any] ?? result["rateLimits"] as? [String: Any]
        guard let snapshot else {
            throw ClientError.malformedResponse
        }

        let windows = ["primary", "secondary"].compactMap { key -> RateWindow? in
            guard let raw = snapshot[key] as? [String: Any],
                  let used = raw["usedPercent"] as? Int else {
                return nil
            }

            return RateWindow(
                used: min(100, max(0, used)),
                duration: raw["windowDurationMins"] as? Int,
                resetsAt: raw["resetsAt"] as? Int
            )
        }

        guard !windows.isEmpty else {
            throw ClientError.malformedResponse
        }

        let short = windows.min { ($0.duration ?? Int.max) < ($1.duration ?? Int.max) } ?? windows[0]
        let weekly = windows.max { ($0.duration ?? 0) < ($1.duration ?? 0) } ?? short

        return LiveRateLimitSnapshot(
            shortUsed: Double(short.used),
            weeklyUsed: Double(weekly.used),
            shortResetsAt: short.resetsAt,
            weeklyResetsAt: weekly.resetsAt
        )
    }

    private struct RateWindow {
        let used: Int
        let duration: Int?
        let resetsAt: Int?
    }
}

@MainActor
enum LimitIconRenderer {
    static func image(used _: Double, tone: NSColor) -> NSImage {
        let size = NSSize(width: 18, height: 14)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let capsule = NSRect(x: 1.0, y: 1.2, width: 16.0, height: 11.6)
        tone.setFill()
        NSBezierPath(roundedRect: capsule, xRadius: 4.2, yRadius: 4.2).fill()

        NSColor.white.withAlphaComponent(0.20).setFill()
        NSBezierPath(
            roundedRect: NSRect(x: 2.3, y: 10.1, width: 13.4, height: 1.2),
            xRadius: 0.6,
            yRadius: 0.6
        ).fill()

        let baselineY: CGFloat = 3.0
        let barWidth: CGFloat = 2.4
        let xPositions: [CGFloat] = [4.0, 7.7, 11.4]
        let heights: [CGFloat] = [3.1, 5.4, 7.8]

        NSColor.white.setFill()
        for (index, x) in xPositions.enumerated() {
            let barRect = NSRect(x: x, y: baselineY, width: barWidth, height: heights[index])
            NSBezierPath(roundedRect: barRect, xRadius: 1.0, yRadius: 1.0).fill()
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
    private let store = LimitStore()
    private var refreshTimer: Timer?

    override init() {
        super.init()

        store.onChange = { [weak self] in
            self?.updateStatusItem()
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 520)
        popover.contentViewController = NSHostingController(rootView: PopoverView(store: store))

        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        updateStatusItem()

        Task {
            await store.refreshFromCodex()
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.store.refreshFromCodex()
            }
        }
    }

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
        guard let button = statusItem.button else {
            return
        }

        let used = store.highestUsed
        button.image = LimitIconRenderer.image(
            used: used,
            tone: nsColor(for: used)
        )
        let title = " \(Int(used.rounded()))%"
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
        )
        button.toolTip = "Codex used: 5h \(Int(store.shortUsed.rounded()))%, weekly \(Int(store.weeklyUsed.rounded()))%"
        button.contentTintColor = nil
    }

    private func nsColor(for value: Double) -> NSColor {
        AppTheme.statusNSColor(forUsed: value)
    }
}

struct PopoverView: View {
    @ObservedObject var store: LimitStore
    @State private var parseMessage = ""
    @State private var showEditor = false

    var body: some View {
        VStack(spacing: 0) {
            titleBar

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    SnapshotHero(store: store)
                    RelationshipPanel(store: store)

                    SectionLabel("Limit windows")

                    LimitRow(
                        title: "5-hour",
                        purpose: "Short-window allowance",
                        used: store.shortUsed,
                        remaining: store.shortRemaining,
                        resetLabel: "In \(store.shortResetText)",
                        isLimiting: store.shortUsed >= store.weeklyUsed,
                        accent: AppTheme.statusColor(forUsed: store.shortUsed)
                    )

                    LimitRow(
                        title: "Weekly",
                        purpose: "Plan-level allowance",
                        used: store.weeklyUsed,
                        remaining: store.weeklyRemaining,
                        resetLabel: store.weeklyResetText,
                        isLimiting: store.weeklyUsed > store.shortUsed,
                        accent: AppTheme.weekly
                    )

                    DisclosureGroup(isExpanded: $showEditor) {
                        EditorPanel(store: store, parseMessage: $parseMessage)
                            .padding(.top, 8)
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Update snapshot")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Manual")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                }
                .padding(14)
            }

            Divider()

            actions
                .padding(12)
        }
        .frame(width: 420, height: 520)
        .background(AppTheme.window)
    }

    private var titleBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "chart.bar.xaxis")
                .foregroundStyle(AppTheme.primary)
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 1) {
                Text("Codex Limit Monitor")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(store.sourceText) - \(store.lastUpdatedText)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task {
                    await store.refreshFromCodex()
                }
            } label: {
                Image(systemName: store.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(store.isRefreshing)
            .help("Refresh Codex usage")

            ToneBadge(title: store.statusTitle, value: store.highestUsed)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.panel)
    }

    private var actions: some View {
        HStack {
            Button("Open Codex") {
                openCodex()
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    private func openCodex() {
        if let codexURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.codex") {
            NSWorkspace.shared.openApplication(at: codexURL, configuration: NSWorkspace.OpenConfiguration())
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Codex"]
        try? process.run()
    }
}

struct SnapshotHero: View {
    @ObservedObject var store: LimitStore

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            LimitMark(short: store.shortUsed, weekly: store.weeklyUsed)
                .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 6) {
                Text("Used so far")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text("\(Int(store.highestUsed.rounded()))%")
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .fontWeight(.semibold)
                    .monospacedDigit()

                Text("\(store.limitingWindowTitle) is currently the higher-used bucket.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

struct LimitMark: View {
    let short: Double
    let weekly: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.13), lineWidth: 7)

            Circle()
                .trim(from: 0, to: weekly / 100)
                .stroke(AppTheme.weekly, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Circle()
                .stroke(Color.secondary.opacity(0.14), lineWidth: 5)
                .frame(width: 34, height: 34)

            Circle()
                .trim(from: 0, to: short / 100)
                .stroke(AppTheme.statusColor(forUsed: short), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 34, height: 34)
                .rotationEffect(.degrees(-90))

            VStack(spacing: -2) {
                Text("\(Int(max(short, weekly).rounded()))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct RelationshipPanel: View {
    @ObservedObject var store: LimitStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Usage relationship")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("max(5h, weekly)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }

            HStack(spacing: 8) {
                MetricTile(title: "5h used", value: "\(Int(store.shortUsed.rounded()))%", footnote: "\(Int(store.shortRemaining.rounded()))% left")
                RelationshipOperator()
                MetricTile(title: "Weekly used", value: "\(Int(store.weeklyUsed.rounded()))%", footnote: "\(Int(store.weeklyRemaining.rounded()))% left")
                RelationshipOperator(symbol: "=")
                MetricTile(title: "Shown now", value: "\(Int(store.highestUsed.rounded()))%", footnote: store.limitingWindowTitle)
            }

            Text("The menu bar shows the most-used bucket. Codex keeps working while both buckets stay below 100%.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let footnote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .monospacedDigit()
            Text(footnote)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

struct RelationshipOperator: View {
    var symbol = "vs"

    var body: some View {
        Text(symbol)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .frame(width: 18)
    }
}

struct SectionLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }
}

struct LimitRow: View {
    let title: String
    let purpose: String
    let used: Double
    let remaining: Double
    let resetLabel: String
    let isLimiting: Bool
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if isLimiting {
                            Text("Limiter")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accent.opacity(0.14))
                                .foregroundStyle(accent)
                                .clipShape(Capsule())
                        }
                    }
                    Text(purpose)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(Int(used.rounded()))%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            QuotaBar(used: used, accent: accent)

            HStack {
                LabelValue(label: "Remaining", value: "\(Int(remaining.rounded()))%")
                Spacer()
                LabelValue(label: "Used", value: "\(Int(used.rounded()))%")
                Spacer()
                LabelValue(label: "Reset", value: resetLabel)
            }
        }
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isLimiting ? accent.opacity(0.55) : AppTheme.border, lineWidth: 1)
        )
    }
}

struct QuotaBar: View {
    let used: Double
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.14))
                Capsule()
                    .fill(accent)
                    .frame(width: max(0, min(proxy.size.width, proxy.size.width * (used / 100))))
            }
        }
        .frame(height: 8)
    }
}

struct LabelValue: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

struct EditorPanel: View {
    @ObservedObject var store: LimitStore
    @Binding var parseMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Values")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Use screenshot") {
                    store.applyScreenshotValues()
                    parseMessage = "Applied"
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                NumberEditor(label: "5h", value: $store.shortUsed)
                TextField("5h reset", text: $store.shortResetText)
                    .textFieldStyle(.roundedBorder)

                NumberEditor(label: "Week", value: $store.weeklyUsed)
                TextField("Weekly reset", text: $store.weeklyResetText)
                    .textFieldStyle(.roundedBorder)
            }

            TextEditor(text: $store.pasteText)
                .font(.system(.caption, design: .monospaced))
                .frame(height: 60)
                .scrollContentBackground(.hidden)
                .background(AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                Button("Parse Text") {
                    parseMessage = store.applyPastedStatus() ? "Updated" : "Need two percentages"
                }

                Text(parseMessage)
                    .foregroundStyle(.secondary)
                    .font(.caption)

                Spacer()
            }
        }
    }
}

struct NumberEditor: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .leading)

            Slider(value: clampedValue, in: 0...100, step: 1)

            TextField("", value: clampedValue, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 54)

            Text("%")
                .foregroundStyle(.secondary)
        }
    }

    private var clampedValue: Binding<Double> {
        Binding(
            get: { min(100, max(0, value)) },
            set: { value = min(100, max(0, $0)) }
        )
    }
}

struct ToneBadge: View {
    let title: String
    let value: Double

    var body: some View {
        Text(title)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(background)
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        AppTheme.statusColor(forUsed: value)
    }

    private var background: Color {
        color.opacity(0.14)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        statusController = StatusController()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
