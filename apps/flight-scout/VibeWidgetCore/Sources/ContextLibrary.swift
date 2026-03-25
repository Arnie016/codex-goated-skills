import Foundation

public struct ContextTextMetrics: Codable, Hashable, Sendable {
    public var characterCount: Int
    public var wordCount: Int
    public var lineCount: Int
    public var estimatedTokenCount: Int
    public var estimatedChunkCount: Int

    public init(
        characterCount: Int = 0,
        wordCount: Int = 0,
        lineCount: Int = 0,
        estimatedTokenCount: Int = 0,
        estimatedChunkCount: Int = 0
    ) {
        self.characterCount = characterCount
        self.wordCount = wordCount
        self.lineCount = lineCount
        self.estimatedTokenCount = estimatedTokenCount
        self.estimatedChunkCount = estimatedChunkCount
    }

    public static func estimate(for text: String, chunkSize: Int = 800) -> ContextTextMetrics {
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        guard !normalizedText.isEmpty else { return ContextTextMetrics() }

        let characterCount = normalizedText.count
        let wordCount = normalizedText.split(whereSeparator: { $0.isWhitespace }).count
        let lineCount = normalizedText.split(separator: "\n", omittingEmptySubsequences: false).count
        let estimatedTokenCount = max(wordCount, Int(ceil(Double(characterCount) / 4.0)))
        let estimatedChunkCount = Int(ceil(Double(estimatedTokenCount) / Double(max(1, chunkSize))))

        return ContextTextMetrics(
            characterCount: characterCount,
            wordCount: wordCount,
            lineCount: lineCount,
            estimatedTokenCount: estimatedTokenCount,
            estimatedChunkCount: estimatedChunkCount
        )
    }
}

public struct ContextDocumentRecord: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var sourcePath: String
    public var storageFileName: String
    public var fileKind: String
    public var fileSizeBytes: Int64
    public var importedAt: Date
    public var modifiedAt: Date?
    public var excerpt: String
    public var metrics: ContextTextMetrics

    public init(
        id: String = UUID().uuidString,
        title: String,
        sourcePath: String,
        storageFileName: String,
        fileKind: String,
        fileSizeBytes: Int64 = 0,
        importedAt: Date = .now,
        modifiedAt: Date? = nil,
        excerpt: String,
        metrics: ContextTextMetrics
    ) {
        self.id = id
        self.title = title
        self.sourcePath = sourcePath
        self.storageFileName = storageFileName
        self.fileKind = fileKind
        self.fileSizeBytes = fileSizeBytes
        self.importedAt = importedAt
        self.modifiedAt = modifiedAt
        self.excerpt = excerpt
        self.metrics = metrics
    }
}

public struct ContextLibrarySnapshot: Codable, Hashable, Sendable {
    public var documents: [ContextDocumentRecord]
    public var lastIndexedAt: Date?

    public init(documents: [ContextDocumentRecord] = [], lastIndexedAt: Date? = nil) {
        self.documents = documents
        self.lastIndexedAt = lastIndexedAt
    }

    public var totalEstimatedTokens: Int {
        documents.reduce(0) { $0 + $1.metrics.estimatedTokenCount }
    }

    public var totalEstimatedChunks: Int {
        documents.reduce(0) { $0 + $1.metrics.estimatedChunkCount }
    }
}
