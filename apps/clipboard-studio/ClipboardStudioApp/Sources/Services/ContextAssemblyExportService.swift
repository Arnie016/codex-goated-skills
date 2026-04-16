import Foundation

enum ContextAssemblyExportService {
    enum ExportError: LocalizedError {
        case notesUnavailable
        case notesExportFailed(String)

        var errorDescription: String? {
            switch self {
            case .notesUnavailable:
                return "Notes is not available for export on this Mac."
            case let .notesExportFailed(message):
                return message.isEmpty ? "The export to Notes failed." : message
            }
        }
    }

    static func suggestedTitle(
        objective: String,
        pack: ContextPack,
        exportedAt: Date = Date()
    ) -> String {
        let trimmedObjective = objective.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedObjective.isEmpty {
            return String(trimmedObjective.prefix(72))
        }

        if let source = pack.items.first?.sourceAppName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !source.isEmpty {
            return "\(ContextAssemblyBrand.appName) from \(source)"
        }

        return "\(ContextAssemblyBrand.appName) \(filenameTimestampFormatter.string(from: exportedAt))"
    }

    static func exportMarkdown(
        document: String,
        title: String,
        to directoryURL: URL,
        exportedAt: Date = Date()
    ) throws -> URL {
        let stem = slug(from: title)
        let fileName = "\(stem)-\(filenameTimestampFormatter.string(from: exportedAt)).md"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try document.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    static func exportToNotes(title: String, document: String) throws {
        let notesURL = URL(fileURLWithPath: "/System/Applications/Notes.app")
        guard FileManager.default.fileExists(atPath: notesURL.path) else {
            throw ExportError.notesUnavailable
        }

        let noteBody = notesHTML(title: title, document: document)
        let script = """
        on run argv
            set noteTitle to item 1 of argv
            set noteBody to item 2 of argv
            tell application "Notes"
                if not running then launch
                tell default account
                    tell default folder
                        make new note with properties {name:noteTitle, body:noteBody}
                    end tell
                end tell
                activate
            end tell
        end run
        """

        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script, title, noteBody]
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw ExportError.notesExportFailed(output)
        }
    }

    private static func slug(from title: String) -> String {
        let lowercase = title.lowercased()
        let pieces = lowercase.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let joined = pieces.joined(separator: "-")
        guard !joined.isEmpty else { return ContextAssemblyBrand.defaultExportStem }
        return String(joined.prefix(48))
    }

    private static func notesHTML(title: String, document: String) -> String {
        let escapedTitle = escapeHTML(title)
        let escapedDocument = escapeHTML(document)
        return """
        <h1>\(escapedTitle)</h1>
        <p><b>Exported from \(ContextAssemblyBrand.appName)</b></p>
        <pre style="font-family: Menlo, ui-monospace, monospace; white-space: pre-wrap;">\(escapedDocument)</pre>
        """
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static let filenameTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
