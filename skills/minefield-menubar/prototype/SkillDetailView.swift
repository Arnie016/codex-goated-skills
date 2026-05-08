import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct MinefieldDetailView: View {
    let sections: [SkillSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(MinefieldTheme.textPrimary)
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(MinefieldTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MinefieldTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MinefieldTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension MinefieldDetailView {
    static var previewSections: [SkillSection] {
        [
            SkillSection(
                title: "Board loop",
                body: "Keep a full Minesweeper-style round playable in one menu-bar popover without feeling cramped."
            ),
            SkillSection(
                title: "Replay feel",
                body: "The reset path should feel instant, so losing still nudges you into one more round."
            ),
            SkillSection(
                title: "Expansion lane",
                body: "Once the shell works, the same top-bar frame can host other polished micro games."
            )
        ]
    }
}
