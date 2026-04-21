import SwiftUI

private struct RelayPreviewItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let symbol: String

    static let samples: [RelayPreviewItem] = [
        .init(name: "Quarterly plan.md", detail: "file, 14 KB", symbol: "doc.text"),
        .init(name: "UI captures", detail: "folder", symbol: "folder"),
        .init(name: "handoff-notes.txt", detail: "file, 3 KB", symbol: "note.text")
    ]
}

struct FinderSelectionRelayMenuBarView: View {
    private let detailLines: [String] = [
        "Reads the current Finder selection or explicit local paths without opening file contents.",
        "Formats exact paths for prompts, markdown notes, ticket bullets, and shell-safe lists.",
        "Keeps the handoff menu-bar first so selected items travel cleanly into the next tool."
    ]

    private let sections = FinderSelectionRelayDetailView.previewSections
    private let items = RelayPreviewItem.samples
    private let formats = ["Prompt", "Markdown", "Shell", "Ticket"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HeaderView()
                StatusChipRow()
                SummaryCard()
                DetailStack(lines: detailLines)
                FormatShortcutRow(formats: formats)
                SelectionList(items: items)
                FinderSelectionRelayDetailView(sections: sections)
                ActionRow()
            }
            .padding(16)
        }
        .frame(width: 388, height: 620)
        .background(FinderSelectionRelayTheme.background)
    }
}

private struct HeaderView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [FinderSelectionRelayTheme.accent, FinderSelectionRelayTheme.accentSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text("Finder Selection Relay")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(FinderSelectionRelayTheme.textPrimary)
                Text("A quiet Finder handoff for files, folders, and clean paths.")
                    .font(.subheadline)
                    .foregroundStyle(FinderSelectionRelayTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct StatusChipRow: View {
    var body: some View {
        HStack(spacing: 8) {
            StatusChip(text: "Workflow Automation")
            StatusChip(text: "5 stars")
            StatusChip(text: "Active")
        }
    }
}

private struct StatusChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(FinderSelectionRelayTheme.textPrimary.opacity(0.88))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(FinderSelectionRelayTheme.panel, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(FinderSelectionRelayTheme.border, lineWidth: 1)
            )
    }
}

private struct SummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current selection")
                .font(.headline)
                .foregroundStyle(FinderSelectionRelayTheme.textPrimary)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("3 items selected")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(FinderSelectionRelayTheme.textPrimary)
                    Text("/Users/arnav/Desktop/Launch assets")
                        .font(.caption)
                        .foregroundStyle(FinderSelectionRelayTheme.textSecondary)
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 4) {
                    MetadataBadge(label: "Files", value: "2")
                    MetadataBadge(label: "Folders", value: "1")
                }
            }
        }
        .padding(14)
        .background(FinderSelectionRelayTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(FinderSelectionRelayTheme.border, lineWidth: 1)
        )
    }
}

private struct MetadataBadge: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(FinderSelectionRelayTheme.textSecondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(FinderSelectionRelayTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(FinderSelectionRelayTheme.background.opacity(0.55), in: Capsule(style: .continuous))
    }
}

private struct DetailStack: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(lines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(FinderSelectionRelayTheme.textSecondary)
            }
        }
        .padding(12)
        .background(FinderSelectionRelayTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FinderSelectionRelayTheme.border, lineWidth: 1)
        )
    }
}

private struct FormatShortcutRow: View {
    let formats: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Format shortcuts")
                .font(.headline)
                .foregroundStyle(FinderSelectionRelayTheme.textPrimary)

            HStack(spacing: 8) {
                ForEach(formats, id: \.self) { format in
                    Text(format)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FinderSelectionRelayTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(FinderSelectionRelayTheme.background.opacity(0.58), in: Capsule(style: .continuous))
                }
            }
        }
    }
}

private struct SelectionList: View {
    let items: [RelayPreviewItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selection preview")
                .font(.headline)
                .foregroundStyle(FinderSelectionRelayTheme.textPrimary)

            VStack(spacing: 8) {
                ForEach(items) { item in
                    SelectionRow(item: item)
                }
            }
        }
    }
}

private struct SelectionRow: View {
    let item: RelayPreviewItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(FinderSelectionRelayTheme.accentSoft)
                .frame(width: 28, height: 28)
                .background(FinderSelectionRelayTheme.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FinderSelectionRelayTheme.textPrimary)
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(FinderSelectionRelayTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(FinderSelectionRelayTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FinderSelectionRelayTheme.border, lineWidth: 1)
        )
    }
}

private struct ActionRow: View {
    var body: some View {
        HStack(spacing: 8) {
            Button("Open Finder") { }
                .buttonStyle(.borderedProminent)

            Button("Copy prompt") { }
                .buttonStyle(.bordered)

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
}
