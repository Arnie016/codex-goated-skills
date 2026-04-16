import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct PatchPilotDetailView: View {
    let sections: [SkillSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(PatchPilotTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(PatchPilotTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PatchPilotTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension PatchPilotDetailView {
    static var previewSections: [SkillSection] {
        [
            SkillSection(
                title: "Input",
                body: "Paste a diff, a staged file list, or a review thread and collapse it into one working brief."
            ),
            SkillSection(
                title: "Decision support",
                body: "Lead with touched areas, likely regressions, and the single next command so the user can act without bouncing between tools."
            ),
            SkillSection(
                title: "Mac feel",
                body: "Use a slim menu-bar popover with one primary recommendation, a compact risk stack, and a copyable reply block."
            )
        ]
    }
}
