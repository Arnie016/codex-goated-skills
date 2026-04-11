import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct SessionArcadeDetailView: View {
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

extension SessionArcadeDetailView {
    static var previewSections: [SkillSection] {
        [
            SkillSection(title: "Session flow", body: "Surface the next game, the current launcher state, and the fastest path to play."),
            SkillSection(title: "Why it works", body: "It saves the small but annoying setup steps that happen before you actually play."),
            SkillSection(title: "Mood", body: "Keep it playful, polished, and short enough to fit in the top bar.")
        ]
    }
}
