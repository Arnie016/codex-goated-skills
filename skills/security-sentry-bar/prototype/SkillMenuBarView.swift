import SwiftUI

struct SecuritySentryBarMenuBarView: View {
    @State private var lastScan = Date()

    private let sections = SecuritySentryDetailView.previewSections

    private var warningCount: Int {
        sections.filter { $0.level == .warning }.count
    }

    private var dangerCount: Int {
        sections.filter { $0.level == .danger }.count
    }

    private var statusColor: Color {
        dangerCount > 0 ? SecuritySentryTheme.danger : (warningCount > 0 ? SecuritySentryTheme.warning : SecuritySentryTheme.safe)
    }

    private var statusSymbol: String {
        dangerCount > 0 ? "exclamationmark.shield.fill" : (warningCount > 0 ? "shield.lefthalf.filled" : "checkmark.shield.fill")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statusStrip
            SecuritySentryDetailView(sections: sections)
            scanPanel
            actionRow
        }
        .padding(16)
        .frame(width: 392)
        .background(SecuritySentryTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(statusColor)
                Image(systemName: statusSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text("Security Sentry Bar")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SecuritySentryTheme.textPrimary)
                Text("Local posture checks for connections, ports, agents, processes, and recent files.")
                    .font(.subheadline)
                    .foregroundStyle(SecuritySentryTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var statusStrip: some View {
        HStack(spacing: 8) {
            StatPill(label: "Warnings", value: "\(warningCount)", color: SecuritySentryTheme.warning)
            StatPill(label: "Dangers", value: "\(dangerCount)", color: SecuritySentryTheme.danger)
            StatPill(label: "Refresh", value: "60s", color: SecuritySentryTheme.accent)
        }
    }

    private var scanPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last scan")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SecuritySentryTheme.textSecondary)
            HStack {
                Text(lastScan, style: .time)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(SecuritySentryTheme.textPrimary)
                Spacer()
                Text("local only")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SecuritySentryTheme.safe)
            }
        }
        .padding(12)
        .background(SecuritySentryTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Run Full Scan") {
                lastScan = Date()
            }
            .buttonStyle(.borderedProminent)

            Button("Copy Summary") { }
                .buttonStyle(.bordered)

            Spacer(minLength: 0)
        }
    }
}

private struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SecuritySentryTheme.textSecondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
