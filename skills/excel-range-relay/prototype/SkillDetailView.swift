import Foundation
import SwiftUI

struct ExcelRangeRelaySection: Identifiable {
    let id: String
    let title: String
    let body: String

    init(title: String, body: String) {
        self.id = title
        self.title = title
        self.body = body
    }
}

struct ExcelRangeRelayDetailView: View {
    let sections: [ExcelRangeRelaySection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(ExcelRangeRelayTheme.textPrimary)
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(ExcelRangeRelayTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ExcelRangeRelayTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension ExcelRangeRelayDetailView {
    static var previewSections: [ExcelRangeRelaySection] {
        [
            ExcelRangeRelaySection(
                title: "Clipboard intake",
                body: "Read the copied Excel selection as structured rows, then attach workbook, sheet, and range labels when Excel is the active app."
            ),
            ExcelRangeRelaySection(
                title: "Header handling",
                body: "Keep the relay deterministic: treat the first copied row as schema when it is real headers, or generate neutral column names when the slice is data-only."
            ),
            ExcelRangeRelaySection(
                title: "Handoff flow",
                body: "Lead with one preview card, a selected output preview, and one primary copy action so the popover feels like a relay, not a spreadsheet clone."
            ),
        ]
    }
}
