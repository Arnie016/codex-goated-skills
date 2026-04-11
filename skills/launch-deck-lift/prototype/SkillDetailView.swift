import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct LaunchDeckLiftDetailView: View {
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

extension LaunchDeckLiftDetailView {
    static var previewSections: [SkillSection] {
        [
            SkillSection(title: "Flow", body: "Start with the story, then map out the slides that support it."),
            SkillSection(title: "Why it helps", body: "It removes the blank-page moment when the deck needs to happen quickly."),
            SkillSection(title: "UI", body: "Use a structured outline and a simple preview surface instead of a giant canvas.")
        ]
    }
}
