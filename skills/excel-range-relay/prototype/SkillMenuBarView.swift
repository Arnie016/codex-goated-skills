import SwiftUI

private enum ExcelRangeRelayOutputPreset: String, CaseIterable, Identifiable {
    case prompt = "Prompt"
    case markdown = "Markdown"
    case csv = "CSV"
    case json = "JSON"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .prompt:
            return "Metadata plus a copy-ready table block"
        case .markdown:
            return "GitHub-friendly table for docs and tickets"
        case .csv:
            return "Spreadsheet-safe export for mail or docs"
        case .json:
            return "Structured rows and records for tooling"
        }
    }

    var systemImage: String {
        switch self {
        case .prompt:
            return "text.bubble"
        case .markdown:
            return "tablecells"
        case .csv:
            return "square.and.arrow.up"
        case .json:
            return "curlybraces"
        }
    }
}

private enum ExcelRangeRelayHeaderMode: String, CaseIterable, Identifiable {
    case firstRow = "First row header"
    case generated = "Generated columns"

    var id: String { rawValue }
}

struct ExcelRangeRelayMenuBarView: View {
    @State private var selectedPreset: ExcelRangeRelayOutputPreset = .prompt
    @State private var headerMode: ExcelRangeRelayHeaderMode = .firstRow

    private let snapshot = ExcelRangeRelaySnapshot.preview
    private let sections = ExcelRangeRelayDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ExcelRangeRelayHeaderView()
            ExcelRangeRelayChipRow()
            ExcelRangeRelaySnapshotCard(snapshot: snapshot, headerMode: headerMode)
            ExcelRangeRelayPreviewTable(snapshot: snapshot, headerMode: headerMode)
            ExcelRangeRelayControls(
                selectedPreset: $selectedPreset,
                headerMode: $headerMode
            )
            ExcelRangeRelayOutputPreviewCard(
                preset: selectedPreset,
                headerMode: headerMode,
                snapshot: snapshot
            )
            ExcelRangeRelayDetailView(sections: sections)
            ExcelRangeRelayActionRow(selectedPreset: selectedPreset)
        }
        .padding(16)
        .frame(width: 392)
        .background(ExcelRangeRelayTheme.background)
    }
}

private struct ExcelRangeRelayChipRow: View {
    var body: some View {
        HStack(spacing: 8) {
            ExcelRangeRelayTagPill(text: "Workflow Automation")
            ExcelRangeRelayTagPill(text: "Clipboard-first")
            ExcelRangeRelayTagPill(text: "Local only")
        }
    }
}

private struct ExcelRangeRelayTagPill: View {
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
                Text("Turn the copied Excel slice into a clean handoff without rebuilding the table by hand.")
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
    let rows: [[String]]

    var rowCount: Int { rows.count }
    var columnCount: Int { rows.first?.count ?? 0 }

    static let preview = ExcelRangeRelaySnapshot(
        workbook: "Q2 planning.xlsx",
        sheet: "Hiring plan",
        rangeAddress: "B3:E7",
        rows: [
            ["Owner", "Region", "Forecast", "Risk"],
            ["Jamie", "APAC", "$182k", "Low"],
            ["Morgan", "EMEA", "$149k", "Medium"],
            ["Taylor", "AMER", "$204k", "Low"],
        ]
    )
}

private struct ExcelRangeRelaySnapshotCard: View {
    let snapshot: ExcelRangeRelaySnapshot
    let headerMode: ExcelRangeRelayHeaderMode

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

                ExcelRangeRelayTagPill(text: "Clipboard ready")
            }

            HStack(spacing: 8) {
                ExcelRangeRelayTagPill(text: "\(snapshot.rowCount) copied rows")
                ExcelRangeRelayTagPill(text: "\(snapshot.columnCount) columns")
                ExcelRangeRelayTagPill(text: headerMode.rawValue)
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
    let snapshot: ExcelRangeRelaySnapshot
    let headerMode: ExcelRangeRelayHeaderMode

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Table preview")
                .font(.headline)
                .foregroundStyle(ExcelRangeRelayTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(previewRows.enumerated()), id: \.offset) { rowIndex, values in
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

    private var previewRows: [[String]] {
        switch headerMode {
        case .firstRow:
            return snapshot.rows
        case .generated:
            return [generatedHeaders] + snapshot.rows
        }
    }

    private var generatedHeaders: [String] {
        (0..<snapshot.columnCount).map { "Column \($0 + 1)" }
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

private struct ExcelRangeRelayControls: View {
    @Binding var selectedPreset: ExcelRangeRelayOutputPreset
    @Binding var headerMode: ExcelRangeRelayHeaderMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExcelRangeRelaySelectorRow(
                title: "Output preset",
                labels: ExcelRangeRelayOutputPreset.allCases.map(\.rawValue),
                selectedLabel: selectedPreset.rawValue
            ) { selectedLabel in
                if let preset = ExcelRangeRelayOutputPreset(rawValue: selectedLabel) {
                    selectedPreset = preset
                }
            }

            ExcelRangeRelaySelectorRow(
                title: "Header mode",
                labels: ExcelRangeRelayHeaderMode.allCases.map(\.rawValue),
                selectedLabel: headerMode.rawValue
            ) { selectedLabel in
                if let mode = ExcelRangeRelayHeaderMode(rawValue: selectedLabel) {
                    headerMode = mode
                }
            }
        }
        .padding(12)
        .background(ExcelRangeRelayTheme.panelStrong, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ExcelRangeRelayTheme.border, lineWidth: 1)
        )
    }
}

private struct ExcelRangeRelaySelectorRow: View {
    let title: String
    let labels: [String]
    let selectedLabel: String
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ExcelRangeRelayTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(labels, id: \.self) { label in
                    Button {
                        onSelect(label)
                    } label: {
                        Text(label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedLabel == label ? .white : ExcelRangeRelayTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selectedLabel == label ? ExcelRangeRelayTheme.accent : ExcelRangeRelayTheme.panel)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ExcelRangeRelayOutputPreviewCard: View {
    let preset: ExcelRangeRelayOutputPreset
    let headerMode: ExcelRangeRelayHeaderMode
    let snapshot: ExcelRangeRelaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(preset.rawValue, systemImage: preset.systemImage)
                .font(.headline)
                .foregroundStyle(ExcelRangeRelayTheme.textPrimary)

            Text(preset.detail)
                .font(.subheadline)
                .foregroundStyle(ExcelRangeRelayTheme.textSecondary)

            ScrollView {
                Text(sampleOutput)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(ExcelRangeRelayTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 124)
            .padding(12)
            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(14)
        .background(ExcelRangeRelayTheme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ExcelRangeRelayTheme.border, lineWidth: 1)
        )
    }

    private var sampleOutput: String {
        let header = effectiveHeader
        let dataRows = effectiveDataRows

        switch preset {
        case .prompt:
            let table = makeMarkdown(header: header, rows: dataRows)
            return """
            Excel selection
            Workbook: \(snapshot.workbook)
            Sheet: \(snapshot.sheet)
            Range: \(snapshot.rangeAddress)
            Header mode: \(headerMode.rawValue)
            Copied rows: \(snapshot.rowCount)
            Data rows: \(dataRows.count)
            Columns: \(snapshot.columnCount)

            Table
            \(table)
            """
        case .markdown:
            return makeMarkdown(header: header, rows: dataRows)
        case .csv:
            return ([header] + dataRows)
                .map { $0.joined(separator: ",") }
                .joined(separator: "\n")
        case .json:
            let records = dataRows.map { row in
                Dictionary(uniqueKeysWithValues: zip(header, row))
            }
            let payload: [String: Any] = [
                "workbook": snapshot.workbook,
                "sheet": snapshot.sheet,
                "range": snapshot.rangeAddress,
                "header_mode": headerMode == .firstRow ? "first-row" : "generated",
                "header": header,
                "records": records,
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
               let text = String(data: data, encoding: .utf8) {
                return text
            }
            return "{ }"
        }
    }

    private var effectiveHeader: [String] {
        if headerMode == .firstRow, let firstRow = snapshot.rows.first {
            return firstRow
        }
        return (0..<snapshot.columnCount).map { "Column \($0 + 1)" }
    }

    private var effectiveDataRows: [[String]] {
        if headerMode == .firstRow {
            return Array(snapshot.rows.dropFirst())
        }
        return snapshot.rows
    }

    private func makeMarkdown(header: [String], rows: [[String]]) -> String {
        let headerLine = "| " + header.joined(separator: " | ") + " |"
        let separator = "| " + Array(repeating: "---", count: header.count).joined(separator: " | ") + " |"
        let body = rows.map { row in
            "| " + row.joined(separator: " | ") + " |"
        }
        return ([headerLine, separator] + body).joined(separator: "\n")
    }
}

private struct ExcelRangeRelayActionRow: View {
    let selectedPreset: ExcelRangeRelayOutputPreset

    var body: some View {
        HStack(spacing: 8) {
            Button("Copy \(selectedPreset.rawValue)") { }
                .buttonStyle(.borderedProminent)
                .tint(ExcelRangeRelayTheme.accent)
            Button("Copy prompt") { }
                .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
    }
}
