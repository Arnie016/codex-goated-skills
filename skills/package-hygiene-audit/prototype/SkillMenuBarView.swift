import SwiftUI

struct PackageHygieneAuditMenuBarView: View {
    private let detailLines: [String] = [
            "Checks the app bundle, release notes, screenshots, and archive outputs in one compact review pass.",
            "Turns the last-mile publish check into one menu-bar stop instead of a Finder and browser scavenger hunt.",
            "Keeps the launch surface strict and calm so missing packaging pieces stand out immediately."
    ]

    private let sections = PackageHygieneAuditDetailView.previewSections

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chipRow
            detailStack
            PackageHygieneAuditDetailView(sections: sections)
            actionRow
        }
        .padding(16)
        .frame(width: 360)
        .background(PackageHygieneAuditTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(PackageHygieneAuditTheme.accent)
                Image(systemName: "checklist.checked")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Package Hygiene Audit")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("A menu-bar audit lane for app bundles, notes, screenshots, and ship files.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            TagPill(text: "Distribution")
            TagPill(text: "5 stars")
            TagPill(text: "Active")
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(detailLines, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Open") { }
                .buttonStyle(.borderedProminent)
            Button("Copy prompt") { }
                .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
}

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.08), in: Capsule(style: .continuous))
    }
}
