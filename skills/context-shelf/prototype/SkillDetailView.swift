import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct ContextShelfDetailView: View {
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

extension ContextShelfDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "What it parks", body: "Capture the front browser tab, the current clipboard snippet, and a quick scratch note into a single bundle that is easy to reopen later.")
        SkillSection(title: "Why it helps", body: "The shelf is for the interruption moment: instead of leaving windows scattered everywhere, you save the state once and come back to a clean resume point.")
        SkillSection(title: "SwiftUI shape", body: "Use a menu-bar popover with one active shelf card, a short recent stack, and a primary Resume action so the whole utility feels native and fast.")
        ]
    }
}
