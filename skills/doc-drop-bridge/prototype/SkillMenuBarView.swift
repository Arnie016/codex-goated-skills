import SwiftUI

struct DocDropBridgeMenuBarView: View {
    private let detailLines: [String] = [
            "Makes it easy to wrap a working note into a shareable artifact.",
            "Keeps PDF, markdown, and plain-text exports close at hand.",
            "Focuses on fast delivery rather than a giant document suite."
    ]

    private let sections = DocDropBridgeDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            DocDropBridgeDetailView(sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 360)
        .background(DocDropBridgeTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DocDropBridgeTheme.accent)
                Image(systemName: "doc.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Doc Drop Bridge")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("A document bridge that stays small and intentional.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Documents")
            TagPill(text: "4 stars")
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
