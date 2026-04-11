import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct FocusRunwayDetailView: View {
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

extension FocusRunwayDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "Launch", body: "Pick a block, open the right surfaces, and reduce the pre-work setup loop."),
        SkillSection(title: "Guardrails", body: "Keep it light and avoid turning focus into another massive dashboard."),
        SkillSection(title: "Tone", body: "The interface should feel like a small helper instead of a command center.")
        ]
    }
}
