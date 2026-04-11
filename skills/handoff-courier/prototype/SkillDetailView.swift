import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct HandoffCourierDetailView: View {
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

extension HandoffCourierDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "What it does", body: "Handoff Courier gives you a small queue for files, clipboard payloads, and exports so transfers feel like one deliberate step instead of a chain of window switches."),
        SkillSection(title: "Why it helps", body: "It is meant for the exact moment where you are bouncing between Codex, Finder, Telegram, browser tabs, and notes and just want a clean drop path."),
        SkillSection(title: "SwiftUI shape", body: "Use a menu-bar popover, a compact transfer card, and a short action row with calm labels so the app behaves like a real Mac utility.")
        ]
    }
}
