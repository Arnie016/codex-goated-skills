import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct DeckExportBundleDetailView: View {
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

extension DeckExportBundleDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "Bundle source", body: "Show the current deck, last export time, and destination lane as one compact source card before anything is packaged.")
        SkillSection(title: "Handoff pack", body: "Lead with one export bundle action, then offer copy notes, reveal package, and share-ready file checks without sending the user into Finder.")
        SkillSection(title: "Why it helps", body: "It removes the repeated Keynote-to-Finder-to-chat loop that happens right before a review, client send, or live presentation.")
        ]
    }
}
