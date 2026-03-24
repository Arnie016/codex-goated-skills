import Foundation
import PDFKit
import UniformTypeIdentifiers
import VibeWidgetCore

struct ContextSearchMatch: Identifiable, Hashable, Sendable {
    let document: ContextDocumentRecord
    let score: Int
    let snippet: String

    var id: String { document.id }
}

actor ContextIngestionService {
    struct ImportReport: Sendable {
        let library: ContextLibrarySnapshot
        let importedCount: Int
        let refreshedCount: Int
        let skippedNames: [String]
    }

    private enum IngestionError: Error {
        case unsupportedType
        case unreadableDocument
        case emptyDocument
    }

    private let fileManager = FileManager.default
    private let maxEnumeratedFiles = 200
    private let maxStoredCharacters = 200_000
    private let supportedExtensions: Set<String> = [
        "c", "cc", "cpp", "cs", "css", "csv", "go", "h", "html", "java", "js",
        "json", "kt", "m", "md", "markdown", "mm", "pdf", "php", "py", "rb",
        "rs", "sh", "sql", "swift", "ts", "tsx", "txt", "xml", "yaml", "yml"
    ]

    func ingest(urls: [URL], into currentLibrary: ContextLibrarySnapshot) async -> ImportReport {
        let candidateURLs = expandedFileURLs(from: urls)
        var documentsByPath = Dictionary(uniqueKeysWithValues: currentLibrary.documents.map { ($0.sourcePath, $0) })
        var importedCount = 0
        var refreshedCount = 0
        var skippedNames: [String] = []

        for url in candidateURLs {
            do {
                let existingRecord = documentsByPath[url.path]
                let record = try ingestDocument(at: url, existing: existingRecord)
                documentsByPath[url.path] = record
                if existingRecord == nil {
                    importedCount += 1
                } else {
                    refreshedCount += 1
                }
            } catch {
                skippedNames.append(url.lastPathComponent)
            }
        }

        let didIndexAnything = importedCount + refreshedCount > 0
        let documents = documentsByPath.values.sorted {
            if $0.importedAt == $1.importedAt {
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            return $0.importedAt > $1.importedAt
        }

        return ImportReport(
            library: ContextLibrarySnapshot(
                documents: documents,
                lastIndexedAt: didIndexAnything ? .now : currentLibrary.lastIndexedAt
            ),
            importedCount: importedCount,
            refreshedCount: refreshedCount,
            skippedNames: skippedNames
        )
    }

    func search(query: String, in library: ContextLibrarySnapshot, limit: Int = 6) async -> [ContextSearchMatch] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else { return [] }

        let terms = trimmedQuery
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { $0.count > 1 }

        var matches: [ContextSearchMatch] = []

        for document in library.documents {
            let content = readStoredContent(for: document) ?? document.excerpt
            let lowercasedContent = content.lowercased()
            let lowercasedTitle = document.title.lowercased()

            var score = 0
            if lowercasedTitle.contains(trimmedQuery) {
                score += 8
            }

            for term in terms {
                if lowercasedTitle.contains(term) {
                    score += 5
                }
                score += min(matchCount(of: term, in: lowercasedContent), 6) * 2
            }

            if score == 0, lowercasedContent.contains(trimmedQuery) {
                score = 3
            }

            guard score > 0 else { continue }
            matches.append(
                ContextSearchMatch(
                    document: document,
                    score: score,
                    snippet: makeSnippet(from: content, for: terms.isEmpty ? [trimmedQuery] : terms)
                )
            )
        }

        return Array(matches.sorted {
            if $0.score == $1.score {
                return $0.document.metrics.estimatedTokenCount > $1.document.metrics.estimatedTokenCount
            }
            return $0.score > $1.score
        }.prefix(limit))
    }

    func removeStoredContent(for documents: [ContextDocumentRecord]) {
        for document in documents {
            try? fileManager.removeItem(at: storageURL(for: document.storageFileName))
        }
    }

    func clearAllStoredContent() {
        let directory = storageDirectoryURL()
        try? fileManager.removeItem(at: directory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func ingestDocument(at url: URL, existing: ContextDocumentRecord?) throws -> ContextDocumentRecord {
        let hasSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let values = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey, .typeIdentifierKey])
        let extractedText = try extractText(from: url, typeIdentifier: values.typeIdentifier)
        let normalizedText = normalize(extractedText)

        guard !normalizedText.isEmpty else {
            throw IngestionError.emptyDocument
        }

        let id = existing?.id ?? UUID().uuidString
        let storageFileName = "\(id).txt"
        try store(text: normalizedText, for: storageFileName)

        return ContextDocumentRecord(
            id: id,
            title: url.lastPathComponent,
            sourcePath: url.path,
            storageFileName: storageFileName,
            fileKind: documentKind(for: url, typeIdentifier: values.typeIdentifier),
            fileSizeBytes: Int64(values.fileSize ?? normalizedText.utf8.count),
            importedAt: .now,
            modifiedAt: values.contentModificationDate,
            excerpt: makeExcerpt(from: normalizedText),
            metrics: ContextTextMetrics.estimate(for: normalizedText)
        )
    }

    private func expandedFileURLs(from urls: [URL]) -> [URL] {
        var collected: [URL] = []
        var seenPaths = Set<String>()

        for url in urls {
            let standardizedURL = url.standardizedFileURL
            guard seenPaths.insert(standardizedURL.path).inserted else { continue }

            let hasSecurityScope = standardizedURL.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScope {
                    standardizedURL.stopAccessingSecurityScopedResource()
                }
            }

            let values = try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            if values?.isDirectory == true {
                guard let enumerator = fileManager.enumerator(
                    at: standardizedURL,
                    includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else {
                    continue
                }

                for case let fileURL as URL in enumerator {
                    guard collected.count < maxEnumeratedFiles else { break }
                    let standardizedFileURL = fileURL.standardizedFileURL
                    let fileValues = try? standardizedFileURL.resourceValues(forKeys: [.isRegularFileKey])
                    guard fileValues?.isRegularFile == true else { continue }
                    guard isSupported(standardizedFileURL), seenPaths.insert(standardizedFileURL.path).inserted else { continue }
                    collected.append(standardizedFileURL)
                }
            } else if values?.isRegularFile == true, isSupported(standardizedURL) {
                collected.append(standardizedURL)
            }
        }

        return collected
    }

    private func isSupported(_ url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        if supportedExtensions.contains(pathExtension) {
            return true
        }

        guard let type = UTType(filenameExtension: pathExtension) else { return false }
        return type.conforms(to: .text)
            || type.conforms(to: .sourceCode)
            || type.conforms(to: .pdf)
            || type.conforms(to: .json)
            || type.conforms(to: .xml)
            || type.conforms(to: .commaSeparatedText)
    }

    private func extractText(from url: URL, typeIdentifier: String?) throws -> String {
        if isPDF(url: url, typeIdentifier: typeIdentifier) {
            guard let document = PDFDocument(url: url), let string = document.string else {
                throw IngestionError.unreadableDocument
            }
            return string
        }

        guard isSupported(url) else {
            throw IngestionError.unsupportedType
        }

        let data = try Data(contentsOf: url)
        if let text = decodeText(data) {
            return text
        }

        throw IngestionError.unreadableDocument
    }

    private func decodeText(_ data: Data) -> String? {
        for encoding in [String.Encoding.utf8, .utf16, .unicode, .ascii, .isoLatin1] {
            if let text = String(data: data, encoding: encoding) {
                return text
            }
        }

        return nil
    }

    private func normalize(_ text: String) -> String {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\0", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.count <= maxStoredCharacters {
            return normalized
        }

        let cutoff = normalized.index(normalized.startIndex, offsetBy: maxStoredCharacters)
        return String(normalized[..<cutoff])
    }

    private func makeExcerpt(from text: String, limit: Int = 240) -> String {
        let flattened = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")

        guard flattened.count > limit else { return flattened }
        let cutoff = flattened.index(flattened.startIndex, offsetBy: limit)
        return "\(flattened[..<cutoff])…"
    }

    private func makeSnippet(from text: String, for terms: [String]) -> String {
        let flattened = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")

        let lowercased = flattened.lowercased()
        for term in terms where !term.isEmpty {
            guard let range = lowercased.range(of: term) else { continue }
            let start = flattened.index(range.lowerBound, offsetBy: -90, limitedBy: flattened.startIndex) ?? flattened.startIndex
            let end = flattened.index(range.upperBound, offsetBy: 140, limitedBy: flattened.endIndex) ?? flattened.endIndex
            let core = String(flattened[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix = start == flattened.startIndex ? "" : "…"
            let suffix = end == flattened.endIndex ? "" : "…"
            return "\(prefix)\(core)\(suffix)"
        }

        return makeExcerpt(from: flattened, limit: 180)
    }

    private func matchCount(of term: String, in text: String) -> Int {
        guard !term.isEmpty else { return 0 }

        var count = 0
        var searchRange = text.startIndex..<text.endIndex

        while let range = text.range(of: term, options: [], range: searchRange) {
            count += 1
            searchRange = range.upperBound..<text.endIndex
        }

        return count
    }

    private func documentKind(for url: URL, typeIdentifier: String?) -> String {
        if isPDF(url: url, typeIdentifier: typeIdentifier) {
            return "PDF"
        }

        if let typeIdentifier {
            let type = UTType(importedAs: typeIdentifier)
            if let description = type.localizedDescription {
                return description
            }
        }

        let pathExtension = url.pathExtension.uppercased()
        return pathExtension.isEmpty ? "Document" : pathExtension
    }

    private func isPDF(url: URL, typeIdentifier: String?) -> Bool {
        if url.pathExtension.lowercased() == "pdf" {
            return true
        }

        guard let typeIdentifier else { return false }
        let type = UTType(importedAs: typeIdentifier)
        return type.conforms(to: .pdf)
    }

    private func store(text: String, for storageFileName: String) throws {
        let directory = storageDirectoryURL()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try text.write(to: storageURL(for: storageFileName), atomically: true, encoding: .utf8)
    }

    private func readStoredContent(for document: ContextDocumentRecord) -> String? {
        try? String(contentsOf: storageURL(for: document.storageFileName), encoding: .utf8)
    }

    private func storageDirectoryURL() -> URL {
        let baseDirectory = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory

        return baseDirectory
            .appendingPathComponent("VibeWidget", isDirectory: true)
            .appendingPathComponent("ContextLibrary", isDirectory: true)
    }

    private func storageURL(for fileName: String) -> URL {
        storageDirectoryURL().appendingPathComponent(fileName, isDirectory: false)
    }
}
