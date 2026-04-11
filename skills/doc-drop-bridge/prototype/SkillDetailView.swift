import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct DocDropBridgeDetailView: View {
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

extension DocDropBridgeDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "Input", body: "Drop in a note, outline, or rough draft and the bridge prepares it for sharing.")
        SkillSection(title: "Output", body: "Choose a compact export path that keeps the result easy to move into another app.")
        SkillSection(title: "Presentation", body: "The interface should read like an Apple utility with one clear action at a time.")
        ]
    }
}
