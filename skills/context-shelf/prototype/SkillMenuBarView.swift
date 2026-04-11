import SwiftUI

struct ContextShelfMenuBarView: View {
    private let detailLines: [String] = [
            "Parks the front tab, clipboard text, and a short scratch note into one compact resume bundle.",
            "Keeps the next thing to reopen visible in the menu bar so task switches stop turning into scavenger hunts.",
            "Stays deliberately small with shelf, pin, resume, and clear actions instead of a sprawling workspace manager."
    ]

    private let sections = ContextShelfDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            ContextShelfDetailView(sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 360)
        .background(ContextShelfTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(ContextShelfTheme.accent)
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Context Shelf")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("A compact resume shelf for tabs, snippets, and scratch notes.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Productivity")
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
            Button("Resume") { }
                .buttonStyle(.borderedProminent)
            Button("Pin Shelf") { }
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
