import SwiftUI

struct FrontTabRelayMenuBarView: View {
    private let detailLines: [String] = [
            "Reads the visible front tab from Safari or common Chrome-family browsers without network access.",
            "Formats the title and URL for markdown, prompts, tickets, or plain-text notes in one step.",
            "Keeps the relay action close to the menu bar so browser context leaves the tab strip cleanly."
    ]

    private let sections = FrontTabRelayDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            FrontTabRelayDetailView(sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 360)
        .background(FrontTabRelayTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(FrontTabRelayTheme.accent)
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Front Tab Relay")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("A quiet menu-bar relay for URLs, titles, and next-destination notes.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
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
