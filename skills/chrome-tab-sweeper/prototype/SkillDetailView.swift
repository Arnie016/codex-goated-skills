import SwiftUI

struct ChromeTabSweeperDomainGroup: Identifiable {
    let id = UUID()
    let domain: String
    let count: Int
    let action: String
}

struct ChromeTabSweeperDetailView: View {
    let groups: [ChromeTabSweeperDomainGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(groups) { group in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.domain)
                            .font(.headline)
                            .foregroundStyle(ChromeTabSweeperTheme.textPrimary)
                        Text(group.action)
                            .font(.caption)
                            .foregroundStyle(ChromeTabSweeperTheme.textSecondary)
                    }
                    Spacer(minLength: 12)
                    Text("\(group.count)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ChromeTabSweeperTheme.accent)
                        .frame(width: 38, alignment: .trailing)
                }
                .padding(12)
                .background(ChromeTabSweeperTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(ChromeTabSweeperTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension ChromeTabSweeperDetailView {
    static var previewGroups: [ChromeTabSweeperDomainGroup] {
        [
            ChromeTabSweeperDomainGroup(domain: "docs.google.com", count: 18, action: "Review duplicate docs"),
            ChromeTabSweeperDomainGroup(domain: "github.com", count: 11, action: "Keep current PR tabs"),
            ChromeTabSweeperDomainGroup(domain: "youtube.com", count: 9, action: "Close watched backlog")
        ]
    }
}
