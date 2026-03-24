import SwiftUI
import UniformTypeIdentifiers

struct DocumentPrepWidgetView: View {
    @ObservedObject var model: AppModel
    @State private var isDropTargeted = false
    @State private var isImporterPresented = false

    private var importTypes: [UTType] {
        [UTType(filenameExtension: "docx") ?? .data, .plainText]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            overview
            dropZone

            if let report = model.documentPrepReport {
                keyPoints(report)
                sectionBreakdown(report)
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: importTypes,
            allowsMultipleSelection: false
        ) { result in
            if case let .success(urls) = result {
                model.prepareDocumentTrainingData(urls)
            }
        }
    }

    private var overview: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Word Doc Prep")
                            .font(.title2.weight(.bold))
                        Text("Turn a large Word document into structured sections, semantic chunks, file-level key points, and export-ready JSONL for retrieval or later fine-tuning work.")
                            .foregroundStyle(.secondary)
                        Text(model.documentPrepStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let report = model.documentPrepReport {
                        HStack(spacing: 10) {
                            MetricCapsule(label: "Sections", value: "\(report.totalSectionCount)")
                            MetricCapsule(label: "Chunks", value: "\(report.totalChunkCount)")
                            MetricCapsule(label: "Tokens", value: formatTokenCount(report.totalTokenCount))
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button("Choose Word Doc") {
                        isImporterPresented = true
                    }
                    .buttonStyle(.borderedProminent)

                    if model.documentPrepReport != nil {
                        Button("Export JSONL") {
                            model.exportPreparedDocumentJSONL()
                        }
                        .buttonStyle(.bordered)

                        if model.documentPrepReport?.exportedJSONLPath != nil {
                            Button("Reveal Export") {
                                model.revealPreparedDocumentExport()
                            }
                            .buttonStyle(.bordered)
                        }

                        Button("Clear") {
                            model.clearPreparedDocument()
                        }
                        .buttonStyle(.borderless)
                    }

                    Spacer()

                    if let report = model.documentPrepReport {
                        Text(tokenMethodLabel(for: report))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                }

                if let exportPath = model.documentPrepReport?.exportedJSONLPath {
                    Text(exportPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var dropZone: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Drop a .docx here", systemImage: "doc.richtext")
                        .font(.headline)
                    Spacer()
                    if model.isPreparingDocument {
                        ProgressView()
                    }
                }

                Text("Best for Word docs where you want structured chunks, section metadata, 5 key points, and JSONL export.")
                    .foregroundStyle(.secondary)

                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(isDropTargeted ? Color.white.opacity(0.09) : Color.white.opacity(0.04))
                    .frame(minHeight: 180)
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(
                                isDropTargeted ? Color.orange : Color.white.opacity(0.5),
                                style: StrokeStyle(lineWidth: 2, dash: [10, 8])
                            )
                    }
                    .overlay {
                        VStack(spacing: 14) {
                            Image(systemName: isDropTargeted ? "doc.badge.gearshape.fill" : "doc.badge.gearshape")
                                .font(.system(size: 36, weight: .bold))
                            Text(isDropTargeted ? "Release to prep training data" : "Drag a Word doc here")
                                .font(.title3.weight(.semibold))
                            Text(model.isPreparingDocument ? "Extracting structure, chunking, and preparing export data..." : "We’ll keep sections, lists, and tables where possible, then build chunk-level metadata.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 460)
                        }
                        .padding(24)
                    }
                    .dropDestination(for: URL.self) { items, _ in
                        model.prepareDocumentTrainingData(items)
                        return !items.isEmpty
                    } isTargeted: { targeted in
                        isDropTargeted = targeted
                    }
            }
        }
    }

    private func keyPoints(_ report: DocumentPrepReport) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("5 Key Points")
                    .font(.headline)

                if report.keyPoints.isEmpty {
                    Text("No key points were extracted yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(report.keyPoints.enumerated()), id: \.offset) { index, point in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.black))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.white.opacity(0.08)))

                            Text(point)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func sectionBreakdown(_ report: DocumentPrepReport) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Section Breakdown")
                        .font(.headline)
                    Spacer()
                    Text(report.sourceFileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(report.sections.prefix(6))) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(section.title)
                                .font(.headline)
                                .lineLimit(1)

                            Text("\(section.tokenCount) tokens")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(section.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            Text(section.sourceLocation)
                            if section.containsTable {
                                Text("table")
                            }
                            if section.containsList {
                                Text("list")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if !section.keywords.isEmpty {
                            Text(section.keywords.joined(separator: " • "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
    }

    private func formatTokenCount(_ value: Int) -> String {
        if value >= 1_000 {
            return String(format: "%.1fk", Double(value) / 1_000)
        }
        return "\(value)"
    }

    private func tokenMethodLabel(for report: DocumentPrepReport) -> String {
        switch report.tokenMethod {
        case "estimated_words_chars":
            return "Estimated tokens"
        default:
            return report.tokenMethod
        }
    }
}
