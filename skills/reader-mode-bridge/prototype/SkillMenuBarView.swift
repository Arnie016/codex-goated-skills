import SwiftUI

struct ReaderModeBridgeMenuBarView: View {
    private let snapshot = ReaderModeBridgeSnapshot.preview
    private let detailLines: [String] = [
        "Cleans clipboard text, saved HTML, markdown, text files, and local PDF excerpts without remote services.",
        "Attaches front-tab title and URL metadata so copied article text keeps its source during the handoff.",
        "Exports markdown, prompt text, plain text, or JSON while surfacing cleanup notes and reading length."
    ]
    private let sections = ReaderModeBridgeDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            sourceCard
            detailStack
            cleanupCard
            ReaderModeBridgeDetailView(sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 372)
        .background(ReaderModeBridgeTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(ReaderModeBridgeTheme.accent)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Reader Mode Bridge")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ReaderModeBridgeTheme.textPrimary)
                Text("A deterministic local reader handoff for pages, PDFs, and copied text.")
                    .font(.subheadline)
                    .foregroundStyle(ReaderModeBridgeTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Documents")
            TagPill(text: "5 stars")
            TagPill(text: "Active")
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(detailLines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(ReaderModeBridgeTheme.textSecondary)
            }
        }
        .padding(12)
        .background(ReaderModeBridgeTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(snapshot.title)
                    .font(.headline)
                    .foregroundStyle(ReaderModeBridgeTheme.textPrimary)
                Spacer(minLength: 0)
                Text("\(snapshot.readingMinutes) min")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ReaderModeBridgeTheme.accentSoft)
            }

            Text(snapshot.sourceLine)
                .font(.caption)
                .foregroundStyle(ReaderModeBridgeTheme.textSecondary)
                .textSelection(.enabled)

            HStack(spacing: 8) {
                MetricPill(label: snapshot.inputKind.uppercased())
                MetricPill(label: "\(snapshot.wordCount) words")
                MetricPill(label: "Markdown")
            }
        }
        .padding(12)
        .background(ReaderModeBridgeTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ReaderModeBridgeTheme.border, lineWidth: 1)
        )
    }

    private var cleanupCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cleanup Notes")
                .font(.headline)
                .foregroundStyle(ReaderModeBridgeTheme.textPrimary)
            ForEach(snapshot.cleanupNotes, id: \.self) { note in
                Label(note, systemImage: "wand.and.stars")
                    .font(.caption)
                    .foregroundStyle(ReaderModeBridgeTheme.textSecondary)
            }
        }
        .padding(12)
        .background(ReaderModeBridgeTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Copy markdown") { }
                .buttonStyle(.borderedProminent)
            Button("Copy prompt") { }
                .buttonStyle(.bordered)
            Button("Reveal source") { }
                .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
}

private struct ReaderModeBridgeSnapshot {
    let title: String
    let sourceLine: String
    let inputKind: String
    let wordCount: Int
    let readingMinutes: Int
    let cleanupNotes: [String]

    static let preview = ReaderModeBridgeSnapshot(
        title: "How teams keep long reads useful after the browser closes",
        sourceLine: "example.com/article - attached from Safari front tab",
        inputKind: "clipboard",
        wordCount: 842,
        readingMinutes: 4,
        cleanupNotes: [
            "Removed share and subscribe lines from the copied body.",
            "Kept the front-tab title and URL as the source anchor.",
            "Trimmed the handoff to the export limit before copying.",
        ]
    )
}

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.08), in: Capsule(style: .continuous))
    }
}

private struct MetricPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(ReaderModeBridgeTheme.accentSoft)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(ReaderModeBridgeTheme.accent.opacity(0.14), in: Capsule(style: .continuous))
    }
}
