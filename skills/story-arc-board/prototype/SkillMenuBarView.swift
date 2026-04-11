import SwiftUI

struct StoryArcBoardMenuBarView: View {
    private let detailLines: [String] = [
            "Pulls recurring phrases, symbols, and post ideas into one compact Mac surface.",
            "Cuts the tab-hopping between Notes, social drafts, and comment threads when shaping the next beat.",
            "Keeps the board lightweight so it feels like a real menu-bar relay instead of a full social dashboard."
    ]

    private let sections = StoryArcBoardDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            StoryArcBoardDetailView(sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 360)
        .background(StoryArcBoardTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(StoryArcBoardTheme.accent)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Story Arc Board")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("A menu-bar board for notes, snippets, and repeated audience beats.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Community & Narrative")
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
            Button("Pin next beat") { }
                .buttonStyle(.borderedProminent)
            Button("Copy brief") { }
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
