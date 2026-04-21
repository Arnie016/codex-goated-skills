import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct ReplayRelayDetailView: View {
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

extension ReplayRelayDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "Capture intake", body: "Show the latest screenshot or a dropped clip as one staging card with preview, title, size, and destination badge already resolved.")
        SkillSection(title: "Share pass", body: "Lead with rename, caption, copy path, and reveal actions so the user can get from capture to Discord, group chat, or notes without Finder detours.")
        SkillSection(title: "Menu-bar tone", body: "Keep the popover playful but disciplined, like a Mac utility that understands gaming rituals without turning into a noisy dashboard.")
        ]
    }
}
