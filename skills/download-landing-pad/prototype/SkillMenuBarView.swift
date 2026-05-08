import SwiftUI

struct DownloadLandingPadMenuBarView: View {
    @State private var selectedID = DownloadLandingPadSample.items[0].id
    @State private var draftName = DownloadLandingPadSample.items[0].suggestedName

    private let items = DownloadLandingPadSample.items

    private var selectedItem: DownloadLandingPadItem {
        items.first(where: { $0.id == selectedID }) ?? items[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DownloadLandingPadHeader()
            DownloadLandingPadSummaryStrip(
                itemCount: items.count,
                selectedDestination: selectedItem.destinationLabel,
                healthSummary: DownloadLandingPadSample.readyCheckSummary
            )

            HStack(alignment: .top, spacing: 14) {
                DownloadArrivalQueue(items: items, selectedID: $selectedID)
                DownloadLandingPadDetailView(item: selectedItem, draftName: $draftName)
            }

            DownloadLandingPadFooter(item: selectedItem, draftName: draftName)
        }
        .padding(16)
        .frame(width: 470)
        .background(DownloadLandingPadTheme.background)
        .onChange(of: selectedID) { _, newValue in
            guard let item = items.first(where: { $0.id == newValue }) else {
                return
            }
            draftName = item.suggestedName
        }
    }
}

private struct DownloadLandingPadHeader: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DownloadLandingPadTheme.accent)
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("Download Landing Pad")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DownloadLandingPadTheme.textPrimary)
                Text("Queue the latest file, rename it cleanly, and route it before Finder clutter takes over.")
                    .font(.subheadline)
                    .foregroundStyle(DownloadLandingPadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct DownloadLandingPadSummaryStrip: View {
    let itemCount: Int
    let selectedDestination: String
    let healthSummary: String

    var body: some View {
        HStack(spacing: 8) {
            DownloadStatPill(label: "\(itemCount) recent files")
            DownloadStatPill(label: healthSummary)
            DownloadStatPill(label: "Reveal + copy path ready")
            DownloadStatPill(label: selectedDestination)
        }
    }
}

private struct DownloadArrivalQueue: View {
    let items: [DownloadLandingPadItem]
    @Binding var selectedID: DownloadLandingPadItem.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent arrivals")
                .font(.headline)
                .foregroundStyle(DownloadLandingPadTheme.textPrimary)

            VStack(spacing: 8) {
                ForEach(items) { item in
                    DownloadArrivalRow(item: item, isSelected: item.id == selectedID) {
                        selectedID = item.id
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 192, alignment: .topLeading)
        .background(DownloadLandingPadTheme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DownloadLandingPadTheme.border, lineWidth: 1)
        )
    }
}

private struct DownloadArrivalRow: View {
    let item: DownloadLandingPadItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DownloadLandingPadTheme.textPrimary)
                    .lineLimit(2)
                Text("\(item.kindLabel) · \(item.ageLabel)")
                    .font(.caption)
                    .foregroundStyle(DownloadLandingPadTheme.textSecondary)
                Text(item.sourceLabel)
                    .font(.caption2)
                    .foregroundStyle(DownloadLandingPadTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                isSelected ? DownloadLandingPadTheme.accent.opacity(0.18) : DownloadLandingPadTheme.panelStrong,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? DownloadLandingPadTheme.accentSoft : DownloadLandingPadTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DownloadLandingPadFooter: View {
    let item: DownloadLandingPadItem
    let draftName: String

    var body: some View {
        HStack(spacing: 8) {
            Button("Reveal latest") { }
                .buttonStyle(.bordered)
            Button("Copy path") { }
                .buttonStyle(.bordered)
            Button("Move to \(item.destinationLabel)") { }
                .buttonStyle(.borderedProminent)
            Spacer(minLength: 0)
            Text(draftName)
                .font(.caption)
                .foregroundStyle(DownloadLandingPadTheme.textMuted)
                .lineLimit(1)
        }
    }
}

private struct DownloadStatPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(DownloadLandingPadTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(DownloadLandingPadTheme.panel, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DownloadLandingPadTheme.border, lineWidth: 1)
            )
    }
}
