import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct MinesweeperDetailView: View {
    let sections: [SkillSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(MinesweeperTheme.textPrimary)
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(MinesweeperTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MinesweeperTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MinesweeperTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension MinesweeperDetailView {
    static var previewSections: [SkillSection] {
        [
            SkillSection(
                title: "Direct app shell",
                body: "The menu bar icon opens straight into the board instead of routing through a launcher screen."
            ),
            SkillSection(
                title: "Compact gameplay",
                body: "Reveal, flag, timer, mine count, and replay stay inside one SwiftUI popover."
            ),
            SkillSection(
                title: "Mac-native feel",
                body: "The UI should read like a polished top-bar utility that happens to be a game."
            )
        ]
    }
}
