import SwiftUI

struct ImpeccableCLIMenuBarView: View {
    private let detailLines: [String] = [
        "Runs the official impeccable CLI against code, folders, or live URLs.",
        "Keeps deterministic findings separate from subjective critique.",
        "Fits one-off audits, CI checks, and pre-commit wiring."
    ]

    private let findings: [(label: String, count: Int, color: Color)] = [
        ("Gradient text", 4, ImpeccableCLITheme.danger),
        ("Low contrast", 2, ImpeccableCLITheme.warning),
        ("Nested cards", 1, ImpeccableCLITheme.accentSoft)
    ]

    private let sections = ImpeccableCLIDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            findingsPanel
            ImpeccableCLIDetailView(sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 372)
        .background(ImpeccableCLITheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ImpeccableCLITheme.accent)
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Impeccable CLI")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ImpeccableCLITheme.textPrimary)
                Text("A compact audit panel for deterministic frontend anti-pattern scans.")
                    .font(.subheadline)
                    .foregroundStyle(ImpeccableCLITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            AuditChip(text: "Developer Tools")
            AuditChip(text: "CLI")
            AuditChip(text: "Active")
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(detailLines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(ImpeccableCLITheme.textSecondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ImpeccableCLITheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ImpeccableCLITheme.border, lineWidth: 1)
        )
    }

    private var findingsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Latest scan: src/")
                .font(.headline)
                .foregroundStyle(ImpeccableCLITheme.textPrimary)

            ForEach(findings, id: \.label) { finding in
                HStack(spacing: 10) {
                    Circle()
                        .fill(finding.color)
                        .frame(width: 10, height: 10)
                    Text(finding.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ImpeccableCLITheme.textPrimary)
                    Spacer(minLength: 0)
                    Text("\(finding.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(ImpeccableCLITheme.textSecondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ImpeccableCLITheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ImpeccableCLITheme.border, lineWidth: 1)
        )
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Run detect") { }
                .buttonStyle(.borderedProminent)
                .tint(ImpeccableCLITheme.accent)

            Button("Copy JSON") { }
                .buttonStyle(.bordered)

            Button("Help") { }
                .buttonStyle(.bordered)

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
}

private struct AuditChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ImpeccableCLITheme.textPrimary.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
    }
}
