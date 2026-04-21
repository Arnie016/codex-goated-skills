import Foundation
import SwiftUI

struct MeetingLinkBridgeCard: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let badge: String
}

struct MeetingLinkBridgeDetailView: View {
    let cards: [MeetingLinkBridgeCard]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(cards) { card in
                HStack(alignment: .top, spacing: 12) {
                    Text(card.badge)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(MeetingLinkBridgeTheme.accentSoft)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(MeetingLinkBridgeTheme.accent.opacity(0.18), in: Capsule(style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                            .font(.headline)
                            .foregroundStyle(MeetingLinkBridgeTheme.textPrimary)
                        Text(card.body)
                            .font(.subheadline)
                            .foregroundStyle(MeetingLinkBridgeTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(MeetingLinkBridgeTheme.panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeetingLinkBridgeTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension MeetingLinkBridgeDetailView {
    static var previewCards: [MeetingLinkBridgeCard] {
        [
            MeetingLinkBridgeCard(
                title: "Provider status",
                body: "Show one Teams-first meeting card with source, provider, and a short code so the active join link is obvious.",
                badge: "SOURCE"
            ),
            MeetingLinkBridgeCard(
                title: "Handoff formats",
                body: "Keep note, email, and markdown outputs ready so the join URL can move into Slack, Outlook, or notes without cleanup.",
                badge: "COPY"
            ),
            MeetingLinkBridgeCard(
                title: "Join lane",
                body: "Offer one open action and one copy action instead of building a giant meeting dashboard around a single link.",
                badge: "OPEN"
            )
        ]
    }
}
