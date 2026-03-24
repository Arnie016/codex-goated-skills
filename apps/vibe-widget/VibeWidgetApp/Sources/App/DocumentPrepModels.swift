import Foundation

struct DocumentPrepSection: Codable, Hashable, Identifiable, Sendable {
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
}

struct DocumentPrepChunk: Codable, Hashable, Identifiable, Sendable {
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

    var id: String { chunkID }
}

struct DocumentPrepReport: Codable, Hashable, Sendable {
    let title: String
    let sourcePath: String
    let tokenMethod: String
    let extractionMode: String
    let sections: [DocumentPrepSection]
    let chunks: [DocumentPrepChunk]
    let keyPoints: [String]
    let preparedAt: Date
    var exportedJSONLPath: String?

    var totalTokenCount: Int {
        chunks.reduce(0) { $0 + $1.tokenCount }
    }

    var totalSectionCount: Int {
        sections.count
    }

    var totalChunkCount: Int {
        chunks.count
    }

    var sourceFileName: String {
        URL(fileURLWithPath: sourcePath).lastPathComponent
    }
}
