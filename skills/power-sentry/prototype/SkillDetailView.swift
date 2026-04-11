import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct PowerSentryDetailView: View {
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

extension PowerSentryDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "At a glance", body: "Show charge, power source, and energy mode first so the user can check the state in one glance."),
        SkillSection(title: "Deeper read", body: "Add trend context only when it helps a real decision like charging or low power mode."),
        SkillSection(title: "Design", body: "Keep the styling monochrome and premium so it feels like a first-party utility.")
        ]
    }
}
