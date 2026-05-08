import SwiftUI

private enum MeetingOutputPreset: String, CaseIterable, Identifiable {
    case note = "Note"
    case email = "Email"
    case markdown = "Markdown"

    var id: String { rawValue }
}

struct MeetingLinkBridgeMenuBarView: View {
    @State private var selectedPreset: MeetingOutputPreset = .note

    private let cards = MeetingLinkBridgeDetailView.previewCards

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MeetingHeaderView()
            MeetingStatusStrip()
            MeetingPresetPicker(selectedPreset: $selectedPreset)
            MeetingLinkBridgeDetailView(cards: cards)
            MeetingPrimaryActionRow(selectedPreset: selectedPreset)
        }
        .padding(16)
        .frame(width: 380)
        .background(MeetingLinkBridgeTheme.background)
    }
}

private struct MeetingHeaderView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MeetingLinkBridgeTheme.accent)
                Image(systemName: "video.badge.plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text("Meeting Link Bridge")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MeetingLinkBridgeTheme.textPrimary)
                Text("Turn the active meeting tab into one clean join handoff.")
                    .font(.subheadline)
                    .foregroundStyle(MeetingLinkBridgeTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct MeetingStatusStrip: View {
    var body: some View {
        HStack(spacing: 8) {
            MeetingStatusPill(label: "Provider", value: "Teams")
            MeetingStatusPill(label: "Source", value: "Edge tab")
            MeetingStatusPill(label: "Code", value: "19:meet")
        }
    }
}

private struct MeetingStatusPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MeetingLinkBridgeTheme.textSecondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(MeetingLinkBridgeTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(MeetingLinkBridgeTheme.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct MeetingPresetPicker: View {
    @Binding var selectedPreset: MeetingOutputPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Handoff format")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MeetingLinkBridgeTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(MeetingOutputPreset.allCases) { preset in
                    Button {
                        selectedPreset = preset
                    } label: {
                        Text(preset.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedPreset == preset ? .white : MeetingLinkBridgeTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selectedPreset == preset ? MeetingLinkBridgeTheme.accent : MeetingLinkBridgeTheme.panel)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(MeetingLinkBridgeTheme.panelStrong, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MeetingLinkBridgeTheme.border, lineWidth: 1)
        )
    }
}

private struct MeetingPrimaryActionRow: View {
    let selectedPreset: MeetingOutputPreset

    var body: some View {
        HStack(spacing: 8) {
            Button("Open link") { }
                .buttonStyle(.borderedProminent)

            Button("Copy \(selectedPreset.rawValue)") { }
                .buttonStyle(.bordered)

            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }
}
