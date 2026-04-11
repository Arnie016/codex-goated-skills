import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct ScreenSnippetStudioDetailView: View {
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

extension ScreenSnippetStudioDetailView {
    static var previewSections: [SkillSection] {
        [
        SkillSection(title: "Capture flow", body: "Take a quick shot, add a short note, and route it into the right workspace without opening a full editor."),
        SkillSection(title: "Signal over noise", body: "The UI should feel more like a quiet staging area than a complicated media tool."),
        SkillSection(title: "Output", body: "Use the result as a prompt, a bug note, or a handoff artifact.")
        ]
    }
}
