import SwiftUI

struct OnThisDayBarMenuBarView: View {
    @ObservedObject var model: OnThisDayBarAppModel

    private let actionColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ZStack {
            OnThisDayBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    headerCard
                    controlsCard
                    spotlightCard
                    timelineCard
                    footerCard
                }
                .padding(10)
                .frame(width: 430)
            }
            .scrollIndicators(.hidden)
        }
        .font(.system(size: 12))
        .controlSize(.small)
    }

    private var headerCard: some View {
        OnThisDayCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [OnThisDayPalette.accent, OnThisDayPalette.accentSoft],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay {
                            Image(systemName: model.menuBarSymbolName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("On This Day")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(OnThisDayPalette.primaryText)
                            OnThisDayStatusPill(title: model.loadState.title, tint: tint(for: model.loadState))
                        }

                        Text(model.dateTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(OnThisDayPalette.primaryText)

                        Text(model.summaryLine)
                            .font(.system(size: 11))
                            .foregroundStyle(OnThisDayPalette.secondaryText)
                            .lineLimit(3)
                    }
                }

                HStack(spacing: 6) {
                    OnThisDayStatusPill(title: "English Wikipedia", tint: OnThisDayPalette.accentSoft)
                    OnThisDayStatusPill(title: OnThisDayDateSupport.daySignal(for: model.selectedDate), tint: OnThisDayPalette.warning)
                }

                HStack(alignment: .top, spacing: 8) {
                    ForEach(model.metricTiles) { metric in
                        OnThisDayMetricTile(metric: metric)
                    }
                }
            }
        }
    }

    private var controlsCard: some View {
        OnThisDayCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Browse")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(OnThisDayPalette.primaryText)
                    Spacer(minLength: 0)
                    Button("Refresh") {
                        Task { await model.refresh(force: true) }
                    }
                    .buttonStyle(OnThisDaySecondaryButtonStyle())
                }

                LazyVGrid(columns: actionColumns, spacing: 8) {
                    Button("Today") { model.jumpToday() }
                        .buttonStyle(OnThisDayPrimaryButtonStyle())
                    Button("Back") { model.moveDate(by: -1) }
                        .buttonStyle(OnThisDaySecondaryButtonStyle())
                    Button("Next") { model.moveDate(by: 1) }
                        .buttonStyle(OnThisDaySecondaryButtonStyle())
                    Button("Random") { model.randomizeDay() }
                        .buttonStyle(OnThisDaySecondaryButtonStyle())
                    Button("Copy Brief") { model.copyDigest() }
                        .buttonStyle(OnThisDaySecondaryButtonStyle())
                    Button("Open Lead") { model.openLead() }
                        .buttonStyle(OnThisDaySecondaryButtonStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("View")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(OnThisDayPalette.mutedText)

                    ForEach(OnThisDayFeedKind.allCases) { kind in
                        OnThisDayKindButton(
                            kind: kind,
                            count: model.count(for: kind),
                            isActive: model.activeKind == kind,
                            action: { model.setKind(kind) }
                        )
                    }
                }

                Stepper(value: storyLimitBinding, in: 3...7) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stories shown: \(model.storyLimit)")
                            .foregroundStyle(OnThisDayPalette.primaryText)
                        Text("Keep the popover focused or let it browse a little deeper.")
                            .font(.system(size: 10.5))
                            .foregroundStyle(OnThisDayPalette.secondaryText)
                    }
                }
            }
        }
    }

    private var spotlightCard: some View {
        OnThisDayCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lead Story")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OnThisDayPalette.primaryText)
                        Text(model.noteLine)
                            .font(.system(size: 10.5))
                            .foregroundStyle(OnThisDayPalette.secondaryText)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    OnThisDayStatusPill(title: model.displayedKind.title, tint: OnThisDayPalette.accentSoft)
                }

                if let spotlight = model.spotlightEntry {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(spotlight.yearLabel)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(OnThisDayPalette.accentSoft)
                            Text(spotlight.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(OnThisDayPalette.primaryText)
                            Text(spotlight.text)
                                .font(.system(size: 11.5))
                                .foregroundStyle(OnThisDayPalette.secondaryText)
                                .lineLimit(4)

                            if !spotlight.pageTags.isEmpty {
                                HStack(spacing: 6) {
                                    ForEach(spotlight.pageTags.prefix(2), id: \.self) { tag in
                                        Text(tag)
                                            .font(.system(size: 9.5, weight: .medium))
                                            .foregroundStyle(OnThisDayPalette.secondaryText)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule(style: .continuous)
                                                    .fill(Color.white.opacity(0.05))
                                            )
                                    }
                                }
                            }
                        }

                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                            if let imageURL = spotlight.imageURL {
                                AsyncImage(url: imageURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Text(spotlight.yearLabel)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(OnThisDayPalette.secondaryText)
                                }
                            } else {
                                Text(spotlight.yearLabel)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(OnThisDayPalette.secondaryText)
                            }
                        }
                        .frame(width: 82, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(OnThisDayPalette.border, lineWidth: 1)
                        )
                    }
                } else {
                    Text("No spotlight is available yet. Refresh or switch the day to fetch a new slice.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(OnThisDayPalette.secondaryText)
                }
            }
        }
    }

    private var timelineCard: some View {
        OnThisDayCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(model.displayedKind.title) on \(OnThisDayDateSupport.monthDay(for: model.selectedDate))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OnThisDayPalette.primaryText)
                Text(model.storySummary)
                    .font(.system(size: 10.5))
                    .foregroundStyle(OnThisDayPalette.secondaryText)

                if model.visibleEntries.isEmpty {
                    Text("No entries surfaced for this slice. Try another day or switch categories.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(OnThisDayPalette.secondaryText)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(OnThisDayPalette.border, lineWidth: 1)
                                )
                        )
                } else {
                    ForEach(model.visibleEntries) { entry in
                        OnThisDayEntryRow(entry: entry, kindTitle: model.displayedKind.title) {
                            model.openEntry(entry)
                        }
                    }
                }
            }
        }
    }

    private var footerCard: some View {
        OnThisDayCard {
            VStack(alignment: .leading, spacing: 10) {
                if let feedback = model.feedbackMessage {
                    Text(feedback)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(OnThisDayPalette.success)
                }

                Text("Powered by the official Wikimedia On This Day feed.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(OnThisDayPalette.secondaryText)

                HStack(spacing: 8) {
                    Button("API Docs") { model.openDocs() }
                        .buttonStyle(OnThisDaySecondaryButtonStyle())
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var storyLimitBinding: Binding<Int> {
        Binding(
            get: { model.storyLimit },
            set: { model.storyLimit = $0 }
        )
    }

    private func tint(for state: OnThisDayLoadState) -> Color {
        switch state {
        case .syncing:
            return OnThisDayPalette.accentSoft
        case .live:
            return OnThisDayPalette.success
        case .cached:
            return OnThisDayPalette.warning
        case .error:
            return OnThisDayPalette.danger
        }
    }
}
