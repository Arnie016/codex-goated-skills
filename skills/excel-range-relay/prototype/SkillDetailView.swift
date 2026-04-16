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
                title: "Format presets",
                body: "Offer markdown table, CSV, JSON, and prompt-context outputs so the same range can move cleanly into chat, docs, or tickets."
            ),
            ExcelRangeRelaySection(
                title: "Handoff flow",
                body: "Lead with one preview card, one primary copy action, and a small preset row so the popover feels like a relay, not a spreadsheet clone."
            ),
        ]
    }
}
