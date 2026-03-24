import Foundation

actor DocumentPreparationService {
    enum DocumentPreparationError: LocalizedError {
        case unsupportedFile
        case extractorMissing
        case extractorFailed(String)
        case invalidOutput

        var errorDescription: String? {
            switch self {
            case .unsupportedFile:
                return "Drop a Word document or a plain-text file to prepare training data."
            case .extractorMissing:
                return "The local document extractor script is missing."
            case let .extractorFailed(message):
                return message
            case .invalidOutput:
                return "The document extractor returned unreadable output."
            }
        }
    }

    private struct ScriptPayload: Decodable {
        let title: String
        let sourcePath: String
        let tokenMethod: String
        let extractionMode: String
        let sections: [ScriptSection]
        let chunks: [ScriptChunk]
        let keyPoints: [String]

        enum CodingKeys: String, CodingKey {
            case title
            case sourcePath = "source_path"
            case tokenMethod = "token_method"
            case extractionMode = "extraction_mode"
            case sections
            case chunks
            case keyPoints = "key_points"
        }
    }

    private struct ScriptSection: Decodable {
        let id: String
        let title: String
        let sectionPath: [String]
        let summary: String
        let keywords: [String]
        let text: String
        let tokenCount: Int
        let containsTable: Bool
        let containsList: Bool
        let sourceLocation: String

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case sectionPath = "section_path"
            case summary
            case keywords
            case text
            case tokenCount = "token_count"
            case containsTable = "contains_table"
            case containsList = "contains_list"
            case sourceLocation = "source_location"
        }
    }

    private struct ScriptChunk: Decodable {
        let chunkID: String
        let docID: String
        let sectionPath: [String]
        let text: String
        let summary: String
        let keywords: [String]
        let tokenCount: Int
        let containsTable: Bool
        let containsList: Bool
        let sourceLocation: String

        enum CodingKeys: String, CodingKey {
            case chunkID = "chunk_id"
            case docID = "doc_id"
            case sectionPath = "section_path"
            case text
            case summary
            case keywords
            case tokenCount = "token_count"
            case containsTable = "contains_table"
            case containsList = "contains_list"
            case sourceLocation = "source_location"
        }
    }

    private struct JSONLRecord: Encodable {
        let docID: String
        let sectionPath: [String]
        let chunkID: String
        let text: String
        let summary: String
        let keywords: [String]
        let tokenCount: Int
        let sourceLocation: String

        enum CodingKeys: String, CodingKey {
            case docID = "doc_id"
            case sectionPath = "section_path"
            case chunkID = "chunk_id"
            case text
            case summary
            case keywords
            case tokenCount = "token_count"
            case sourceLocation = "source_location"
        }
    }

    private let fileManager = FileManager.default
    private let scriptPath = "/Users/arnav/Desktop/sora/scripts/extract_doc_training_data.py"
    private let supportedExtensions: Set<String> = ["docx", "md", "markdown", "txt"]

    func prepareDocument(at url: URL) async throws -> DocumentPrepReport {
        let standardizedURL = url.standardizedFileURL
        guard supportedExtensions.contains(standardizedURL.pathExtension.lowercased()) else {
            throw DocumentPreparationError.unsupportedFile
        }

        guard fileManager.fileExists(atPath: scriptPath) else {
            throw DocumentPreparationError.extractorMissing
        }

        let hasSecurityScope = standardizedURL.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope {
                standardizedURL.stopAccessingSecurityScopedResource()
            }
        }

        let outputData = try runExtractor(for: standardizedURL)
        let decoder = JSONDecoder()
        let payload = try decoder.decode(ScriptPayload.self, from: outputData)

        return DocumentPrepReport(
            title: payload.title,
            sourcePath: payload.sourcePath,
            tokenMethod: payload.tokenMethod,
            extractionMode: payload.extractionMode,
            sections: payload.sections.map {
                DocumentPrepSection(
                    id: $0.id,
                    title: $0.title,
                    sectionPath: $0.sectionPath,
                    summary: $0.summary,
                    keywords: $0.keywords,
                    text: $0.text,
                    tokenCount: $0.tokenCount,
                    containsTable: $0.containsTable,
                    containsList: $0.containsList,
                    sourceLocation: $0.sourceLocation
                )
            },
            chunks: payload.chunks.map {
                DocumentPrepChunk(
                    chunkID: $0.chunkID,
                    docID: $0.docID,
                    sectionPath: $0.sectionPath,
                    text: $0.text,
                    summary: $0.summary,
                    keywords: $0.keywords,
                    tokenCount: $0.tokenCount,
                    containsTable: $0.containsTable,
                    containsList: $0.containsList,
                    sourceLocation: $0.sourceLocation
                )
            },
            keyPoints: payload.keyPoints,
            preparedAt: .now,
            exportedJSONLPath: nil
        )
    }

    func exportJSONL(for report: DocumentPrepReport) throws -> URL {
        let exportDirectory = try exportDirectoryURL()
        let exportURL = exportDirectory.appendingPathComponent("\(slug(for: report.title))-chunks.jsonl", isDirectory: false)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let lines = try report.chunks.map { chunk in
            let record = JSONLRecord(
                docID: chunk.docID,
                sectionPath: chunk.sectionPath,
                chunkID: chunk.chunkID,
                text: chunk.text,
                summary: chunk.summary,
                keywords: chunk.keywords,
                tokenCount: chunk.tokenCount,
                sourceLocation: chunk.sourceLocation
            )
            let data = try encoder.encode(record)
            guard let line = String(data: data, encoding: .utf8) else {
                throw DocumentPreparationError.invalidOutput
            }
            return line
        }

        try lines.joined(separator: "\n").write(to: exportURL, atomically: true, encoding: .utf8)
        return exportURL
    }

    private func runExtractor(for url: URL) throws -> Data {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptPath, url.path]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw DocumentPreparationError.extractorFailed("Python could not start for document prep.")
        }

        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorText = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let outputText = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            let message = errorText.isEmpty ? outputText : errorText
            throw DocumentPreparationError.extractorFailed(message.isEmpty ? "The document extractor failed." : message)
        }

        guard !outputData.isEmpty else {
            throw DocumentPreparationError.invalidOutput
        }

        return outputData
    }

    private func exportDirectoryURL() throws -> URL {
        let baseDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let directory = baseDirectory
            .appendingPathComponent("VibeWidget", isDirectory: true)
            .appendingPathComponent("DocPrepExports", isDirectory: true)

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func slug(for title: String) -> String {
        let cleaned = title
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return cleaned.isEmpty ? "document" : cleaned
    }
}
