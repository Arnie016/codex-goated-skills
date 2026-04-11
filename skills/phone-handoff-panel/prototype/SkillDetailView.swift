import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct PhoneHandoffPanelDetailView: View {
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

extension PhoneHandoffPanelDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "Device loop", body: "Surface the phone actions that matter now instead of every possible option.")
        SkillSection(title: "Behavior", body: "Lead with open, locate, and continue actions because those are the ones people repeat.")
        SkillSection(title: "Mac feel", body: "The UI should stay calm, compact, and native so it belongs in the menu bar.")
        ]
    }
}
