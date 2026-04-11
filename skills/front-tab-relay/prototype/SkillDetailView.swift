import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct FrontTabRelayDetailView: View {
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

extension FrontTabRelayDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "Capture flow", body: "Read the front tab title, URL, and domain from the active supported browser and show them as one small relay card.")
        SkillSection(title: "Routing presets", body: "Offer one-tap output shapes for markdown links, prompt context, and ticket bullets so the next destination is already structured.")
        SkillSection(title: "Mac feel", body: "Keep the panel narrow and deliberate with a recent relay strip instead of a crowded browser dashboard.")
        ]
    }
}
