import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct RepoOpsLensDetailView: View {
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

extension RepoOpsLensDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "What it scans", body: "The app can summarize a repo, surface high-risk areas, and show the next safe command or fix to run."),
        SkillSection(title: "Why it matters", body: "It cuts the time spent switching between browser, terminal, and notes when you only need the gist."),
        SkillSection(title: "UI tone", body: "Use a narrow, readable panel with strong hierarchy and one primary recommendation.")
        ]
    }
}
