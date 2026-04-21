import SwiftUI

enum ReplyQueueBucket: String, CaseIterable, Identifiable {
    case urgent
    case reusable
    case archive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .urgent:
            return "Urgent"
        case .reusable:
            return "Reusable"
        case .archive:
            return "Archive"
        }
    }

    var sectionTitle: String {
        switch self {
        case .urgent:
            return "Urgent replies"
        case .reusable:
            return "Reusable answers"
        case .archive:
            return "Archive lane"
        }
    }

    var symbol: String {
        switch self {
        case .urgent:
            return "exclamationmark.bubble.fill"
        case .reusable:
            return "text.bubble.fill"
        case .archive:
            return "archivebox.fill"
        }
    }

    var tint: Color {
        switch self {
        case .urgent:
            return ReplyQueueBarTheme.accent
        case .reusable:
            return ReplyQueueBarTheme.reusable
        case .archive:
            return ReplyQueueBarTheme.archive
        }
    }

    var emptyState: String {
        switch self {
        case .urgent:
            return "Capture the next copied comment into the urgent lane when it needs a real answer today."
        case .reusable:
            return "Store repeat questions here so the next draft is one glance away."
        case .archive:
            return "Archive resolved snippets here after the reply is already out in the world."
        }
    }
}

struct ReplyQueueItem: Identifiable {
    let id: String
    let source: String
    let text: String
    let bucket: ReplyQueueBucket
    let urgencyLabel: String
    let tags: [String]
    let draft: String
    let receivedLabel: String
}

struct ReplyQueueSnapshot {
    let items: [ReplyQueueItem]

    var nextItem: ReplyQueueItem? {
        items.first(where: { $0.bucket != .archive })
    }

    func count(for bucket: ReplyQueueBucket) -> Int {
        items.filter { $0.bucket == bucket }.count
    }

    func items(for bucket: ReplyQueueBucket) -> [ReplyQueueItem] {
        items.filter { $0.bucket == bucket }
    }
}

extension ReplyQueueSnapshot {
    static let preview = ReplyQueueSnapshot(
        items: [
            ReplyQueueItem(
                id: "rqb-20260413-120101",
                source: "X replies",
                text: "Can you pin the Friday build notes link so new people stop asking where the changelog lives?",
                bucket: .urgent,
                urgencyLabel: "High",
                tags: ["launch", "faq"],
                draft: "Pinned in the latest Friday update thread. I’ll keep the build notes linked there after each drop.",
                receivedLabel: "Copied just now"
            ),
            ReplyQueueItem(
                id: "rqb-20260413-113144",
                source: "Telegram DM",
                text: "Do you have a short answer I can reuse when people ask what the daily brief pack actually includes?",
                bucket: .reusable,
                urgencyLabel: "Normal",
                tags: ["pack", "faq"],
                draft: "It bundles the day brief, on-this-day history, and market-reading archive tools so the ritual is already assembled.",
                receivedLabel: "Copied 18m ago"
            ),
            ReplyQueueItem(
                id: "rqb-20260413-101522",
                source: "Support inbox",
                text: "Thanks, that fixed it. You can close this thread.",
                bucket: .archive,
                urgencyLabel: "Low",
                tags: ["resolved"],
                draft: "Resolved and archived.",
                receivedLabel: "Handled 1h ago"
            ),
        ]
    )
}

struct ReplyQueueDetailSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct ReplyQueueBarDetailView: View {
    let sections: [ReplyQueueDetailSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(ReplyQueueBarTheme.textPrimary)
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(ReplyQueueBarTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(ReplyQueueBarTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ReplyQueueBarTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension ReplyQueueBarDetailView {
    static let previewSections: [ReplyQueueDetailSection] = [
        ReplyQueueDetailSection(
            title: "Queue snapshot",
            body: "Lead with open counts and the next actionable reply so the user can answer first and reorganize later."
        ),
        ReplyQueueDetailSection(
            title: "Bucket switcher",
            body: "Keep urgent, reusable, and archive buckets close so the queue feels like one compact relay instead of another inbox."
        ),
        ReplyQueueDetailSection(
            title: "Draft handoff",
            body: "Pair the selected reply with one short draft, one copy action, and one archive move so the answer leaves the menu bar cleanly."
        ),
    ]
}
