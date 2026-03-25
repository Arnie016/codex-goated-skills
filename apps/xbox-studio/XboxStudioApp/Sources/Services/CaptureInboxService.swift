import AppKit
import Foundation

enum CaptureInboxError: LocalizedError {
    case unsupportedFiles

    var errorDescription: String? {
        switch self {
        case .unsupportedFiles:
            return "Drop image or video capture files such as .mp4, .mov, .png, or .jpg."
        }
    }
}

struct CaptureImportResult {
    let importedCount: Int

    var message: String {
        importedCount == 1 ? "Imported 1 capture into the inbox." : "Imported \(importedCount) captures into the inbox."
    }
}

final class CaptureInboxService {
    private let fileManager: FileManager
    private let byteFormatter = ByteCountFormatter()
    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    let captureDirectory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        captureDirectory = baseDirectory
            .appending(path: "Xbox Studio", directoryHint: .isDirectory)
            .appending(path: "Captures", directoryHint: .isDirectory)

        try? fileManager.createDirectory(at: captureDirectory, withIntermediateDirectories: true)
    }

    func loadAssets() -> [CaptureAsset] {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]
        let urls = (try? fileManager.contentsOfDirectory(at: captureDirectory, includingPropertiesForKeys: Array(keys)))
            ?? []

        return urls.compactMap { url in
            guard isSupported(url) else { return nil }
            let values = try? url.resourceValues(forKeys: keys)
            guard values?.isRegularFile == true else { return nil }

            let sizeText: String
            if let size = values?.fileSize {
                sizeText = byteFormatter.string(fromByteCount: Int64(size))
            } else {
                sizeText = "Unknown size"
            }

            let dateText: String
            if let modified = values?.contentModificationDate {
                dateText = dateFormatter.localizedString(for: modified, relativeTo: Date())
            } else {
                dateText = "Unknown date"
            }

            return CaptureAsset(
                id: url.path,
                fileURL: url,
                title: url.deletingPathExtension().lastPathComponent,
                subtitle: "\(sizeText) • \(dateText)",
                badge: badge(for: url)
            )
        }
        .sorted { lhs, rhs in
            lhs.fileURL.lastPathComponent.localizedCaseInsensitiveCompare(rhs.fileURL.lastPathComponent) == .orderedAscending
        }
    }

    func importFiles(from urls: [URL]) throws -> String {
        var importedCount = 0

        for url in urls where isSupported(url) {
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let destination = uniqueDestination(for: url.lastPathComponent)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: url, to: destination)
            importedCount += 1
        }

        guard importedCount > 0 else {
            throw CaptureInboxError.unsupportedFiles
        }

        return CaptureImportResult(importedCount: importedCount).message
    }

    func openCaptureFolder() {
        NSWorkspace.shared.open(captureDirectory)
    }

    func reveal(_ asset: CaptureAsset) {
        NSWorkspace.shared.activateFileViewerSelecting([asset.fileURL])
    }

    private func uniqueDestination(for fileName: String) -> URL {
        let original = captureDirectory.appending(path: fileName)
        guard fileManager.fileExists(atPath: original.path) else {
            return original
        }

        let sourceURL = URL(fileURLWithPath: fileName)
        let base = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension

        for index in 2...99 {
            let candidateName = ext.isEmpty ? "\(base)-\(index)" : "\(base)-\(index).\(ext)"
            let candidate = captureDirectory.appending(path: candidateName)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return captureDirectory.appending(path: UUID().uuidString + "-" + fileName)
    }

    private func isSupported(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "m4v", "png", "jpg", "jpeg", "heic", "gif"].contains(ext)
    }

    private func badge(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "mp4", "mov", "m4v":
            return "Video"
        case "png", "jpg", "jpeg", "heic", "gif":
            return "Image"
        default:
            return "File"
        }
    }
}
