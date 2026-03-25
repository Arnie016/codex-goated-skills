import Foundation

actor FlightScoutPersistenceStore {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let rootDirectory: URL

    init(rootDirectory: URL? = nil) {
        let fileManager = FileManager.default
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else if let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            self.rootDirectory = applicationSupport.appending(path: "FlightScout", directoryHint: .isDirectory)
        } else {
            self.rootDirectory = fileManager.temporaryDirectory.appending(path: "FlightScout", directoryHint: .isDirectory)
        }

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    private var riskCacheURL: URL { rootDirectory.appending(path: "risk-cache.json") }
    private var seenHistoryURL: URL { rootDirectory.appending(path: "seen-routes.json") }
    private var savedURL: URL { rootDirectory.appending(path: "saved-routes.json") }
    private var exportsDirectoryURL: URL { rootDirectory.appending(path: "Exports", directoryHint: .isDirectory) }

    func ensureDirectories() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: exportsDirectoryURL, withIntermediateDirectories: true)
    }

    func loadRiskCache() -> [String: TravelRiskSourceCacheEntry] {
        loadJSON(at: riskCacheURL, defaultValue: [:])
    }

    func saveRiskCache(_ cache: [String: TravelRiskSourceCacheEntry]) throws {
        try ensureDirectories()
        try saveJSON(cache, to: riskCacheURL)
    }

    func loadSeenHistory() -> [String: Date] {
        loadJSON(at: seenHistoryURL, defaultValue: [:])
    }

    func saveSeenHistory(_ history: [String: Date]) throws {
        try ensureDirectories()
        try saveJSON(history, to: seenHistoryURL)
    }

    func loadSavedOpportunities() -> [SavedFlightOpportunity] {
        loadJSON(at: savedURL, defaultValue: [])
    }

    func saveSavedOpportunities(_ items: [SavedFlightOpportunity]) throws {
        try ensureDirectories()
        try saveJSON(items, to: savedURL)
    }

    func latestExports() -> [FlightExportArtifact] {
        let fileManager = FileManager.default
        let urls = (try? fileManager.contentsOfDirectory(at: exportsDirectoryURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles])) ?? []
        return urls.sorted { lhs, rhs in
            let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return leftDate > rightDate
        }.compactMap { url in
            switch url.pathExtension.lowercased() {
            case "md":
                return FlightExportArtifact(kind: .markdown, fileURL: url)
            case "csv":
                return FlightExportArtifact(kind: .csv, fileURL: url)
            case "json":
                return FlightExportArtifact(kind: .json, fileURL: url)
            default:
                return nil
            }
        }
    }

    func exportDigest(routes: [SavedFlightOpportunity], title: String) throws -> [FlightExportArtifact] {
        try ensureDirectories()
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let safeTitle = FlightScoutFormatting.safeFilename(title)

        let markdownURL = exportsDirectoryURL.appending(path: "\(safeTitle)-\(timestamp).md")
        let csvURL = exportsDirectoryURL.appending(path: "\(safeTitle)-\(timestamp).csv")
        let jsonURL = exportsDirectoryURL.appending(path: "\(safeTitle)-\(timestamp).json")

        try markdownDigest(for: routes, title: title).write(to: markdownURL, atomically: true, encoding: .utf8)
        try csvDigest(for: routes).write(to: csvURL, atomically: true, encoding: .utf8)
        try encoder.encode(routes).write(to: jsonURL, options: .atomic)

        return [
            FlightExportArtifact(kind: .markdown, fileURL: markdownURL),
            FlightExportArtifact(kind: .csv, fileURL: csvURL),
            FlightExportArtifact(kind: .json, fileURL: jsonURL)
        ]
    }

    func pruneSeenHistory(_ history: [String: Date], keepingDays: Int = 7, now: Date = Date()) -> [String: Date] {
        let cutoff = now.addingTimeInterval(-Double(keepingDays) * 86_400)
        return history.filter { $0.value >= cutoff }
    }

    private func loadJSON<T: Decodable>(at url: URL, defaultValue: T) -> T {
        guard let data = try? Data(contentsOf: url) else { return defaultValue }
        return (try? decoder.decode(T.self, from: data)) ?? defaultValue
    }

    private func saveJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }

    private func markdownDigest(for routes: [SavedFlightOpportunity], title: String) -> String {
        var lines = ["# \(title)", "", "Generated \(Date().formatted(date: .abbreviated, time: .shortened))", ""]
        for route in routes {
            lines.append("## \(route.originName) -> \(route.destinationName)")
            lines.append("- Price: \(route.priceDisplay)")
            lines.append("- Provider: \(route.providerName)")
            lines.append("- Risk: \(route.riskLevel.title)")
            lines.append("- Book: \(route.bookingURL.absoluteString)")
            lines.append("- Saved: \(route.savedAt.formatted(date: .abbreviated, time: .shortened))")
            lines.append("")
            lines.append(route.summary)
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private func csvDigest(for routes: [SavedFlightOpportunity]) -> String {
        let header = ["origin", "destination", "price", "provider", "risk", "booking_url", "summary", "saved_at"].joined(separator: ",")
        let rows = routes.map { route in
            [
                FlightScoutFormatting.csvEscaped(route.originName),
                FlightScoutFormatting.csvEscaped(route.destinationName),
                FlightScoutFormatting.csvEscaped(route.priceDisplay),
                FlightScoutFormatting.csvEscaped(route.providerName),
                FlightScoutFormatting.csvEscaped(route.riskLevel.title),
                FlightScoutFormatting.csvEscaped(route.bookingURL.absoluteString),
                FlightScoutFormatting.csvEscaped(route.summary),
                FlightScoutFormatting.csvEscaped(route.savedAt.ISO8601Format())
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }
}
