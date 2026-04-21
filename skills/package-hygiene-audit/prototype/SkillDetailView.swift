import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct PackageHygieneAuditDetailView: View {
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

extension PackageHygieneAuditDetailView {
    static var previewSections: [SkillSection] {
        [
            SkillSection(title: "Audit pass", body: "Show the current release folder as one checklist card with bundle, archive, screenshots, and notes already grouped by ship readiness."),
            SkillSection(title: "Why it helps", body: "It removes the repeated Finder-to-browser-to-notes loop that happens right before a release when attention is already fragmented."),
            SkillSection(title: "UI direction", body: "Use a compact status stack with one blocking issue state, one ready-to-ship state, and a short action row for reveal, copy, and export."),
        ]
    }
}
