import Foundation
import VibeWidgetCore

struct PaperBridgeArtifact: Identifiable, Hashable {
    let id: Int
    let name: String
    let sizeInBytes: Int
    let expired: Bool
    let createdAt: Date
    let archiveDownloadURL: URL

    var downloadFilename: String {
        "\(name).zip"
    }

    var sizeLabel: String {
        ByteCountFormatter.string(fromByteCount: Int64(sizeInBytes), countStyle: .file)
    }
}

struct PaperBridgeRun: Identifiable, Hashable {
    let id: Int
    let runNumber: Int
    let workflowName: String
    let displayTitle: String
    let event: String
    let status: String
    let conclusion: String?
    let branch: String
    let createdAt: Date
    let updatedAt: Date
    let htmlURL: URL
    var artifacts: [PaperBridgeArtifact]

    var stateLabel: String {
        if status == "completed" {
            switch conclusion {
            case "success":
                return "Succeeded"
            case "failure":
                return "Failed"
            case "cancelled":
                return "Cancelled"
            case "timed_out":
                return "Timed Out"
            case "neutral":
                return "Completed"
            default:
                return "Completed"
            }
        }

        switch status {
        case "queued":
            return "Queued"
        case "in_progress":
            return "Running"
        case "requested":
            return "Requested"
        case "waiting":
            return "Waiting"
        case "pending":
            return "Pending"
        default:
            return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var isFinished: Bool {
        status == "completed"
    }

    var primaryArtifact: PaperBridgeArtifact? {
        artifacts.first { !$0.expired }
    }
}

struct PaperBridgeWorkflowSnapshot {
    let recentRuns: [PaperBridgeRun]

    var latestRun: PaperBridgeRun? {
        recentRuns.first
    }
}

extension AppSettings {
    var hasPaperBridgeConfiguration: Bool {
        !paperRepositoryOwner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !paperRepositoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !paperWorkflowIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !paperRepositoryRef.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var paperRepositorySlug: String {
        let owner = paperRepositoryOwner.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = paperRepositoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        if owner.isEmpty || name.isEmpty {
            return "owner/repo"
        }
        return "\(owner)/\(name)"
    }
}
