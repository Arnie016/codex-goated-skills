import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct StoryArcBoardDetailView: View {
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
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}

extension StoryArcBoardDetailView {
    static var previewSections: [SkillSection] {
        [
            SkillSection(title: "Capture lane", body: "Collect phrases, screenshots, and quick notes from the apps you already have open."),
            SkillSection(title: "Why it helps", body: "It turns scattered narrative scraps into one visible queue before context disappears."),
            SkillSection(title: "Menu-bar shape", body: "Use a compact popover with pinned beats, a short intake list, and one clean action to promote the next arc.")
        ]
    }
}
