import SwiftUI

struct DeckExportBundleMenuBarView: View {
    private let detailLines: [String] = [
            "Pulls the live deck, speaker notes, and output format into one send-ready bundle card.",
            "Keeps PDF export, notes text, and reveal-in-Finder actions together before the handoff leaves your Mac.",
            "Turns last-mile deck packaging into one calm menu-bar step instead of a Finder and chat scramble."
    ]

    private let sections = DeckExportBundleDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            DeckExportBundleDetailView(sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 360)
        .background(DeckExportBundleTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DeckExportBundleTheme.accent)
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Deck Export Bundle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("A compact export lane for polished slide handoffs from the menu bar.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Presentation")
            TagPill(text: "5 stars")
            TagPill(text: "Active")
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(detailLines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Open") { }
                .buttonStyle(.borderedProminent)
            Button("Copy prompt") { }
                .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
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
