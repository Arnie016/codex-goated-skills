import SwiftUI

struct DownloadLandingPadItem: Identifiable, Hashable {
    let id: String
    let name: String
    let kindLabel: String
    let sourceLabel: String
    let ageLabel: String
    let sizeLabel: String
    let suggestedName: String
    let destinationLabel: String
    let routeOptions: [String]
}

struct DownloadLandingPadHealthCheck: Identifiable, Hashable {
    enum Status: String {
        case ready = "Ready"
        case warning = "Warning"
        case limited = "Limited"

        var color: Color {
            switch self {
            case .ready:
                return DownloadLandingPadTheme.success
            case .warning:
                return DownloadLandingPadTheme.warning
            case .limited:
                return DownloadLandingPadTheme.danger
            }
        }
    }

    let id: String
    let label: String
    let detail: String
    let status: Status
}

enum DownloadLandingPadSample {
    static let items: [DownloadLandingPadItem] = [
        DownloadLandingPadItem(
            id: "launch-png",
            name: "Screen Shot 2026-04-13 at 12.02.18.png",
            kindLabel: "Screenshot",
            sourceLabel: "figma.com",
            ageLabel: "2m ago",
            sizeLabel: "3.2 MB",
            suggestedName: "launch-review-screenshot.png",
            destinationLabel: "Design review folder",
            routeOptions: ["Ticket comment", "Design review folder", "Chat upload"]
        ),
        DownloadLandingPadItem(
            id: "brief-pdf",
            name: "Investor Brief Draft.pdf",
            kindLabel: "Document",
            sourceLabel: "notion.so",
            ageLabel: "11m ago",
            sizeLabel: "942 KB",
            suggestedName: "investor-brief-draft.pdf",
            destinationLabel: "Reference folder",
            routeOptions: ["Reference folder", "Meeting notes", "Share-ready handoff"]
        ),
        DownloadLandingPadItem(
            id: "pricing-csv",
            name: "pricing-export.csv",
            kindLabel: "Spreadsheet",
            sourceLabel: "docs.google.com",
            ageLabel: "24m ago",
            sizeLabel: "118 KB",
            suggestedName: "pricing-export.csv",
            destinationLabel: "Analysis workspace",
            routeOptions: ["Analysis workspace", "Finance folder", "Prompt context"]
        ),
    ]

    static let healthChecks: [DownloadLandingPadHealthCheck] = [
        DownloadLandingPadHealthCheck(
            id: "downloads",
            label: "Downloads access",
            detail: "31 visible files in ~/Downloads",
            status: .ready
        ),
        DownloadLandingPadHealthCheck(
            id: "metadata",
            label: "Source hints",
            detail: "Spotlight metadata is available for recent files",
            status: .ready
        ),
        DownloadLandingPadHealthCheck(
            id: "reveal",
            label: "Reveal support",
            detail: "Finder reveal is available for the selected file",
            status: .ready
        ),
        DownloadLandingPadHealthCheck(
            id: "writes",
            label: "Safe writes",
            detail: "Rename and move stay preview-first until confirmed",
            status: .warning
        ),
    ]

    static var readyCheckSummary: String {
        let readyCount = healthChecks.filter { $0.status == .ready }.count
        return "\(readyCount)/\(healthChecks.count) checks ready"
    }
}

struct DownloadLandingPadDetailView: View {
    let item: DownloadLandingPadItem
    @Binding var draftName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DownloadFocusCard(item: item)
            DownloadHealthPanel(checks: DownloadLandingPadSample.healthChecks)
            DownloadRenamePanel(draftName: $draftName, originalName: item.name)
            DownloadRoutePanel(destinationLabel: item.destinationLabel, routeOptions: item.routeOptions)
        }
    }
}

private struct DownloadFocusCard: View {
    let item: DownloadLandingPadItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DownloadLandingPadTheme.accent.opacity(0.18))
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DownloadLandingPadTheme.accentSoft)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(DownloadLandingPadTheme.textPrimary)
                        .lineLimit(2)
                    Text("\(item.kindLabel) · \(item.sourceLabel)")
                        .font(.subheadline)
                        .foregroundStyle(DownloadLandingPadTheme.textSecondary)
                    Text("\(item.ageLabel) · \(item.sizeLabel)")
                        .font(.caption)
                        .foregroundStyle(DownloadLandingPadTheme.textMuted)
                }
            }

            Text("Selected destination: \(item.destinationLabel)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DownloadLandingPadTheme.success)
        }
        .padding(14)
        .background(DownloadLandingPadTheme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DownloadLandingPadTheme.border, lineWidth: 1)
        )
    }
}

private struct DownloadHealthPanel: View {
    let checks: [DownloadLandingPadHealthCheck]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Readiness doctor")
                    .font(.headline)
                    .foregroundStyle(DownloadLandingPadTheme.textPrimary)
                Spacer(minLength: 0)
                Text(DownloadLandingPadSample.readyCheckSummary)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DownloadLandingPadTheme.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(checks) { check in
                    DownloadHealthRow(check: check)
                }
            }
        }
        .padding(14)
        .background(DownloadLandingPadTheme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DownloadLandingPadTheme.border, lineWidth: 1)
        )
    }
}

private struct DownloadHealthRow: View {
    let check: DownloadLandingPadHealthCheck

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(check.status.color)
                .frame(width: 10, height: 10)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(check.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DownloadLandingPadTheme.textPrimary)
                Text(check.detail)
                    .font(.caption)
                    .foregroundStyle(DownloadLandingPadTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Text(check.status.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(check.status.color)
        }
    }
}

private struct DownloadRenamePanel: View {
    @Binding var draftName: String
    let originalName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rename dock")
                .font(.headline)
                .foregroundStyle(DownloadLandingPadTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Suggested name", text: $draftName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(DownloadLandingPadTheme.panelStrong, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DownloadLandingPadTheme.border, lineWidth: 1)
                    )

                Text("Original: \(originalName)")
                    .font(.caption)
                    .foregroundStyle(DownloadLandingPadTheme.textMuted)
            }

            HStack(spacing: 8) {
                Button("Preview rename") { }
                    .buttonStyle(.borderedProminent)
                Button("Copy name") { }
                    .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(DownloadLandingPadTheme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DownloadLandingPadTheme.border, lineWidth: 1)
        )
    }
}

private struct DownloadRoutePanel: View {
    let destinationLabel: String
    let routeOptions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Route options")
                .font(.headline)
                .foregroundStyle(DownloadLandingPadTheme.textPrimary)

            Text("Next lane: \(destinationLabel)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DownloadLandingPadTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(routeOptions, id: \.self) { option in
                    DownloadRouteChip(label: option, isHighlighted: option == destinationLabel)
                }
            }

            HStack(spacing: 8) {
                Button("Reveal in Finder") { }
                    .buttonStyle(.bordered)
                Button("Copy path") { }
                    .buttonStyle(.bordered)
                Button("Move") { }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(DownloadLandingPadTheme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DownloadLandingPadTheme.border, lineWidth: 1)
        )
    }
}

private struct DownloadRouteChip: View {
    let label: String
    let isHighlighted: Bool

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isHighlighted ? DownloadLandingPadTheme.textPrimary : DownloadLandingPadTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isHighlighted ? DownloadLandingPadTheme.accent.opacity(0.22) : DownloadLandingPadTheme.panelStrong,
                in: Capsule(style: .continuous)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DownloadLandingPadTheme.border, lineWidth: 1)
            )
    }
}
