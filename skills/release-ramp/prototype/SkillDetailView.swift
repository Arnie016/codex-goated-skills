import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct ReleaseRampDetailView: View {
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

extension ReleaseRampDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "Launch surface", body: "The app shows the current release step, what is left, and the next clean move.")
        SkillSection(title: "Why it helps", body: "It reduces the friction of remembering release steps when the room is already busy.")
        SkillSection(title: "Design direction", body: "Use one bold action, two supporting checks, and a restrained progress strip.")
        ]
    }
}
