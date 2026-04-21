import SwiftUI

struct BranchBriefBarMenuBarView: View {
    private let detailLines: [String] = [
        "Local git state only: branch, upstream distance, working tree counts, and recent commits.",
        "Preview the key changed files with committed, staged, unstaged, or untracked state before someone opens the diff.",
        "Default the compare base toward a main-like review branch when the upstream is only the same remote feature branch.",
        "Choose the compare base explicitly when that default is not the right review baseline.",
        "One reviewer-facing brief that is already shaped for PR updates, notes, or chat.",
        "A compact relay step, not a GitHub dashboard or CI monitor."
    ]

    private let snapshot = BranchBriefSnapshot.preview
    private let sections = BranchBriefBarDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            BranchBriefBarDetailView(snapshot: snapshot, sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 380)
        .background(BranchBriefBarTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(BranchBriefBarTheme.accent)
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Branch Brief Bar")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BranchBriefBarTheme.textPrimary)
                Text("A menu-bar git brief for branch health, touched areas, changed files, recent commits, and the next review action.")
                    .font(.subheadline)
                    .foregroundStyle(BranchBriefBarTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Developer Tools")
            TagPill(text: "Git-first")
            TagPill(text: "Review-base aware")
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(detailLines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(BranchBriefBarTheme.textSecondary)
            }
        }
        .padding(12)
        .background(BranchBriefBarTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(BranchBriefBarTheme.border, lineWidth: 1)
        )
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Copy brief") { }
                .buttonStyle(.borderedProminent)
            Button("Open repo") { }
                .buttonStyle(.bordered)
            Button("View diff") { }
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
            .foregroundStyle(BranchBriefBarTheme.textPrimary.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.08), in: Capsule(style: .continuous))
    }
}
