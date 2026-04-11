import SwiftUI

struct ChromeTabSweeperMenuBarView: View {
    @State private var selectedCount = 12

    private let groups = ChromeTabSweeperDetailView.previewGroups

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statusStrip
            ChromeTabSweeperDetailView(groups: groups)
            cleanupPanel
            actionRow
        }
        .padding(16)
        .frame(width: 380)
        .background(ChromeTabSweeperTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ChromeTabSweeperTheme.accent)
                Image(systemName: "rectangle.stack.badge.minus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text("Chrome Tab Sweeper")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ChromeTabSweeperTheme.textPrimary)
                Text("See the tab pile from the menu bar, then close only the selected batch.")
                    .font(.subheadline)
                    .foregroundStyle(ChromeTabSweeperTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var statusStrip: some View {
        HStack(spacing: 8) {
            StatPill(label: "Tabs", value: "148")
            StatPill(label: "Windows", value: "7")
            StatPill(label: "Ready", value: "\(selectedCount)")
        }
    }

    private var cleanupPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected cleanup")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ChromeTabSweeperTheme.textSecondary)
            HStack {
                Text("\(selectedCount) tabs")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(ChromeTabSweeperTheme.textPrimary)
                Spacer()
                Text("review first")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ChromeTabSweeperTheme.secondary)
            }
        }
        .padding(12)
        .background(ChromeTabSweeperTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Scan Chrome") { }
                .buttonStyle(.borderedProminent)
            Button("Close Selected") { }
                .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
    }
}

private struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(ChromeTabSweeperTheme.textSecondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(ChromeTabSweeperTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
