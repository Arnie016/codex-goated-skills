import SwiftUI

struct ExcelRangeRelayMenuBarView: View {
    private let snapshot = ExcelRangeRelaySnapshot.preview
    private let presets = ExcelRangeRelayPreset.previewPresets
    private let detailLines = [
        "Clipboard-first handoff that keeps Excel table shape intact.",
        "Workbook, sheet, and range labels only when local Excel metadata is available.",
        "Markdown, CSV, JSON, and prompt outputs in one quiet relay surface.",
    ]

    private let sections = ExcelRangeRelayDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ExcelRangeRelayHeaderView()
            chipRow
            ExcelRangeRelaySnapshotCard(snapshot: snapshot)
            ExcelRangeRelayPreviewTable(rows: snapshot.previewRows)
            ExcelRangeRelayPresetGrid(presets: presets)
            detailStack
            ExcelRangeRelayDetailView(sections: sections)
            ExcelRangeRelayActionRow()
        }
        .padding(16)
        .frame(width: 388)
        .background(ExcelRangeRelayTheme.background)
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Workflow Automation")
            TagPill(text: "5 stars")
            TagPill(text: "Active")
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(detailLines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(ExcelRangeRelayTheme.textSecondary)
            }
        }
        .padding(12)
        .background(ExcelRangeRelayTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ExcelRangeRelayTheme.border, lineWidth: 1)
        )
    }
}

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ExcelRangeRelayTheme.textPrimary.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ExcelRangeRelayTheme.panel, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ExcelRangeRelayTheme.border, lineWidth: 1)
            )
    }
}

private struct ExcelRangeRelayHeaderView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ExcelRangeRelayTheme.accent)
                Image(systemName: "tablecells")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text("Excel Range Relay")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ExcelRangeRelayTheme.textPrimary)
                Text("Clipboard-first spreadsheet handoffs for markdown tables, prompt context, and clean exports.")
                    .font(.subheadline)
                    .foregroundStyle(ExcelRangeRelayTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct ExcelRangeRelaySnapshot {
    let workbook: String
    let sheet: String
    let rangeAddress: String
    let rowCount: Int
    let columnCount: Int
    let previewRows: [[String]]

    static let preview = ExcelRangeRelaySnapshot(
        workbook: "Q2 planning.xlsx",
        sheet: "Hiring plan",
        rangeAddress: "B3:E7",
        rowCount: 5,
        columnCount: 4,
        previewRows: [
            ["Owner", "Region", "Forecast", "Risk"],
            ["Jamie", "APAC", "$182k", "Low"],
            ["Morgan", "EMEA", "$149k", "Medium"],
            ["Taylor", "AMER", "$204k", "Low"],
        ]
    )
}

private struct ExcelRangeRelaySnapshotCard: View {
    let snapshot: ExcelRangeRelaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.workbook)
                        .font(.headline)
                        .foregroundStyle(ExcelRangeRelayTheme.textPrimary)
                    Text("\(snapshot.sheet) · \(snapshot.rangeAddress)")
                        .font(.subheadline)
                        .foregroundStyle(ExcelRangeRelayTheme.textSecondary)
                }

                Spacer(minLength: 12)

                TagPill(text: "Clipboard ready")
            }

            HStack(spacing: 8) {
                TagPill(text: "\(snapshot.rowCount) rows")
                TagPill(text: "\(snapshot.columnCount) columns")
                TagPill(text: "Excel label")
            }
        }
        .padding(14)
        .background(ExcelRangeRelayTheme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ExcelRangeRelayTheme.border, lineWidth: 1)
        )
    }
}

private struct ExcelRangeRelayPreviewTable: View {
    let rows: [[String]]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Clipboard preview")
                .font(.headline)
                .foregroundStyle(ExcelRangeRelayTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, values in
                    ExcelRangeRelayTableRow(values: values, isHeader: rowIndex == 0)
                }
            }
        }
        .padding(14)
        .background(ExcelRangeRelayTheme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ExcelRangeRelayTheme.border, lineWidth: 1)
        )
    }
}

private struct ExcelRangeRelayTableRow: View {
    let values: [String]
    let isHeader: Bool

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text(value)
                    .font(.system(size: 11, weight: isHeader ? .semibold : .regular, design: .monospaced))
                    .foregroundStyle(isHeader ? ExcelRangeRelayTheme.textPrimary : ExcelRangeRelayTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(
                        isHeader ? ExcelRangeRelayTheme.accent.opacity(0.22) : Color.white.opacity(0.03),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
            }
        }
    }
}

private struct ExcelRangeRelayPreset: Identifiable {
    let title: String
    let detail: String
    let systemImage: String

    var id: String { title }

    static let previewPresets: [ExcelRangeRelayPreset] = [
        ExcelRangeRelayPreset(title: "Markdown", detail: "Header row + GitHub table", systemImage: "tablecells"),
        ExcelRangeRelayPreset(title: "Prompt", detail: "Metadata plus table block", systemImage: "text.bubble"),
        ExcelRangeRelayPreset(title: "CSV", detail: "Clean export for mail or docs", systemImage: "square.and.arrow.up"),
        ExcelRangeRelayPreset(title: "JSON", detail: "Structured rows for tooling", systemImage: "curlybraces"),
    ]
}

private struct ExcelRangeRelayPresetGrid: View {
    let presets: [ExcelRangeRelayPreset]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(presets) { preset in
                VStack(alignment: .leading, spacing: 8) {
                    Label(preset.title, systemImage: preset.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ExcelRangeRelayTheme.textPrimary)
                    Text(preset.detail)
                        .font(.caption)
                        .foregroundStyle(ExcelRangeRelayTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ExcelRangeRelayTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

private struct ExcelRangeRelayActionRow: View {
    var body: some View {
        HStack(spacing: 8) {
            Button("Copy prompt") { }
                .buttonStyle(.borderedProminent)
                .tint(ExcelRangeRelayTheme.accent)
            Button("Markdown") { }
                .buttonStyle(.bordered)
            Button("CSV") { }
                .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
    }
}
