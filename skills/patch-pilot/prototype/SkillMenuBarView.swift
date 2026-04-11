import SwiftUI

struct PatchPilotMenuBarView: View {
    private let detailLines: [String] = [
        "Turns a copied diff or file list into the next safe move before the tool-switching spiral starts.",
        "Keeps touched surfaces, likely regressions, and reply-ready notes in one compact panel.",
        "Fits the pre-commit, pre-review, and pre-handoff moment where context usually fragments."
    ]

    private let sections = PatchPilotDetailView.previewSections

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                chipRow
                briefCard
                detailStack
                PatchPilotDetailView(sections: sections)
                actionRow
            }
            .padding(16)
        }
        .frame(width: 372, height: 620)
        .background(PatchPilotTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(PatchPilotTheme.accent)
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Patch Pilot")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PatchPilotTheme.textPrimary)
                Text("A menu-bar patch triage panel for fix briefs, risk notes, and the next safe command.")
                    .font(.subheadline)
                    .foregroundStyle(PatchPilotTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Developer Tools")
            TagPill(text: "5 stars")
            TagPill(text: "Active")
        }
    }

    private var briefCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next safe move")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Collapse the patch into touched surfaces, likely regressions, and one reply-ready brief before you edit.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
            Label("Triage before you switch tools again", systemImage: "bolt.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [PatchPilotTheme.accent.opacity(0.9), PatchPilotTheme.accentSoft.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(detailLines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.74))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PatchPilotTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(PatchPilotTheme.border, lineWidth: 1)
        )
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Summarize diff") { }
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
