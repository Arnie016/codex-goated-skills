import Foundation
import SwiftUI

struct ReaderModeBridgeSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct ReaderModeBridgeDetailView: View {
    let sections: [ReaderModeBridgeSection]

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

extension ReaderModeBridgeDetailView {
    static var previewSections: [ReaderModeBridgeSection] {
        [
            ReaderModeBridgeSection(
                title: "Intake",
                body: "Bring in clipboard text, saved HTML, local markdown or text, or a PDF excerpt and keep the source card compact."
            ),
            ReaderModeBridgeSection(
                title: "Cleanup",
                body: "Show the chosen title, source, cleanup notes, and estimated reading length before the export leaves the Mac."
            ),
            ReaderModeBridgeSection(
                title: "Output",
                body: "Offer markdown, prompt, plain text, and copy actions because the handoff should be ready for notes, chat, or Codex immediately."
            ),
        ]
    }
}
