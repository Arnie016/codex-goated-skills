import SwiftUI
import UniformTypeIdentifiers
import VibeWidgetCore

struct ContextStudioView: View {
    @ObservedObject var model: AppModel
    @State private var isDropTargeted = false
    @State private var isImporterPresented = false

    private let importTypes: [UTType] = [.folder, .plainText, .pdf, .json, .xml, .commaSeparatedText, .sourceCode]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                overview
                dropZone
                DocumentPrepWidgetView(model: model)
                library
            }
            .padding(.bottom, 4)
        }
        .scrollIndicators(.hidden)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: importTypes,
            allowsMultipleSelection: true
        ) { result in
            if case let .success(urls) = result {
                model.ingestContextFiles(urls)
            }
        }
    }

    private var overview: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("File tokenizer")
                            .font(.title2.weight(.bold))
                        Text("Drop files or folders in and get instant local token estimates. This app now only focuses on ingesting files and counting tokens.")
                            .foregroundStyle(.secondary)
                        Text(model.contextStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 10) {
                        HStack(spacing: 10) {
                            MetricCapsule(label: "Files", value: "\(model.contextLibrary.documents.count)")
                            MetricCapsule(label: "Est. Tokens", value: model.contextTokenSummary)
                            MetricCapsule(label: "Chunks", value: "\(model.contextLibrary.totalEstimatedChunks)")
                        }

                        if let lastIndexedAt = model.contextLibrary.lastIndexedAt {
                            Text("Last indexed \(lastIndexedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var dropZone: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Drop files here", systemImage: "tray.and.arrow.down")
                        .font(.headline)
                    Spacer()
                    Button("Choose Files") {
                        isImporterPresented = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text("Supports folders plus text-heavy formats like `.md`, `.txt`, code, `.json`, `.csv`, `.xml`, and `.pdf`.")
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
                            Image(systemName: isDropTargeted ? "shippingbox.fill" : "shippingbox")
                                .font(.system(size: 36, weight: .bold))
                            Text(isDropTargeted ? "Release to tokenize your pack" : "Drag documents, folders, or code here")
                                .font(.title3.weight(.semibold))
                            Text(model.isIndexingContext ? "Indexing now..." : "We’ll extract readable text and estimate token counts right away.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 420)
                        }
                        .padding(24)
                    }
                    .dropDestination(for: URL.self) { items, _ in
                        model.ingestContextFiles(items)
                        return !items.isEmpty
                    } isTargeted: { targeted in
                        isDropTargeted = targeted
                    }
            }
        }
    }

    private var library: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Tokenized files")
                        .font(.headline)
                    Spacer()
                    if !model.contextLibrary.documents.isEmpty {
                        Button("Clear Pack") {
                            model.clearContextLibrary()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if model.contextLibrary.documents.isEmpty {
                    Text("Nothing indexed yet. Drop a file or folder to start counting tokens.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.contextDocuments) { document in
                        ContextDocumentRow(document: document) {
                            model.removeContextDocument(document)
                        }
                    }
                }
            }
        }
    }
}

private struct ContextDocumentRow: View {
    let document: ContextDocumentRecord
    let onRemove: () -> Void

    private var byteCountFormatter: ByteCountFormatter {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                ContextDocumentCompactRow(document: document)

                HStack(spacing: 10) {
                    Text("\(document.metrics.wordCount) words")
                    Text("\(document.metrics.lineCount) lines")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .trailing, spacing: 10) {
                Text(byteCountFormatter.string(fromByteCount: document.fileSizeBytes))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(document.importedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.bold))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}
