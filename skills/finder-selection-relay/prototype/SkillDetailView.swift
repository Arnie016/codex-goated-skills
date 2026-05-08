import SwiftUI

struct FinderSelectionRelaySection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct FinderSelectionRelayDetailView: View {
    let sections: [FinderSelectionRelaySection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(FinderSelectionRelayTheme.textPrimary)
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(FinderSelectionRelayTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(FinderSelectionRelayTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(FinderSelectionRelayTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension FinderSelectionRelayDetailView {
    static let previewSections: [FinderSelectionRelaySection] = [
        .init(
            title: "Selection summary",
            body: "Show item count, common location, and a small metadata lane so the user can confirm the Finder selection or explicit path batch before copying anything."
        ),
        .init(
            title: "Format shortcuts",
            body: "Offer one-tap output shapes for prompt context, markdown notes, ticket bullets, and shell-safe paths so the next destination needs less cleanup."
        ),
        .init(
            title: "Menu-bar feel",
            body: "Keep the panel narrow, deliberate, and easy to scan instead of drifting into a full Finder replacement or file manager."
        )
    ]
}
