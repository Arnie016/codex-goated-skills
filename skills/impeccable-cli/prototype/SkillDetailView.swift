import Foundation
import SwiftUI

struct ImpeccableSkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct ImpeccableCLIDetailView: View {
    let sections: [ImpeccableSkillSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(ImpeccableCLITheme.textPrimary)
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(ImpeccableCLITheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ImpeccableCLITheme.panel)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ImpeccableCLITheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension ImpeccableCLIDetailView {
    static var previewSections: [ImpeccableSkillSection] {
        [
            ImpeccableSkillSection(
                title: "Target",
                body: "Switch between a directory like src/ and a live URL without changing the audit flow."
            ),
            ImpeccableSkillSection(
                title: "Finding shape",
                body: "Summarize the highest-signal issues first: contrast, hierarchy, nested cards, gradient text, and similar deterministic hits."
            ),
            ImpeccableSkillSection(
                title: "Actions",
                body: "Keep quick affordances for rerun, copy JSON, and open the command reference so the scan can drop into CI or a review loop."
            )
        ]
    }
}
