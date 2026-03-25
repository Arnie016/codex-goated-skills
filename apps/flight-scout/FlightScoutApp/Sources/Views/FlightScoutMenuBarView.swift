import SwiftUI

struct FlightScoutMenuBarView: View {
    @ObservedObject var model: FlightScoutAppModel
    @State private var isShowingDateEditor = false

    var body: some View {
        ZStack {
            FlightScoutBackdrop()

            FlightScoutPanelSurface {
                headerSection

                if model.feedbackMessage != nil || model.errorMessage != nil {
                    FlightScoutSectionDivider()
                    statusSection
                }

                FlightScoutSectionDivider()
                liveRoutesSection
                FlightScoutSectionDivider()
                actionSection
            }
            .padding(8)
            .frame(width: 340)
        }
        .controlSize(.small)
        .font(.system(size: 12.5))
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlightScoutSectionLabel(text: "Flying From")

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.panelTitle)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.97))
                        .lineLimit(1)

                    Text(model.panelSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.46))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 6) {
                    if model.newOpportunityCount > 0 {
                        FlightScoutBadge(text: "\(min(99, model.newOpportunityCount)) new", tint: .blue)
                    }

                    HStack(spacing: 6) {
                        Button {
                            model.openBoard()
                        } label: {
                            CompactFlightIconButton(symbolName: "square.grid.2x2")
                        }
                        .buttonStyle(.plain)
                        .help("Open board")

                        Button {
                            model.refreshNow()
                        } label: {
                            CompactFlightIconButton(
                                symbolName: model.isLoading ? "arrow.trianglehead.2.clockwise.rotate.90" : "arrow.clockwise"
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isLoading)
                        .help("Refresh routes")
                    }
                }
            }

            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isShowingDateEditor.toggle()
                    }
                } label: {
                    FlightScoutPill(text: dateSummary, tint: .blue)
                }
                .buttonStyle(.plain)

                FlightScoutPill(text: model.settings.cabinClass.title, tint: .cyan)
                FlightScoutPill(
                    text: model.selectedFilter == .safest ? "\(model.saferOpportunityCount) safer" : "\(trackedCount) tracked",
                    tint: model.selectedFilter == .safest ? .green : .mint
                )
            }

            if isShowingDateEditor {
                CompactDateEditor(model: model)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let feedback = model.feedbackMessage {
                FlightStatusBanner(message: feedback, tint: .green, symbolName: "checkmark.circle.fill")
            }
            if let error = model.errorMessage {
                FlightStatusBanner(message: error, tint: .orange, symbolName: "exclamationmark.triangle.fill")
            }
        }
    }

    private var liveRoutesSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                FlightScoutSectionLabel(text: "Top Routes")
                Spacer(minLength: 0)
                Text("\(model.topPanelRoutes.count) shown")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.42))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(FlightFilter.allCases) { filter in
                        Button {
                            model.selectedFilter = filter
                        } label: {
                            FlightScoutFilterChip(
                                title: filter.title,
                                isSelected: model.selectedFilter == filter,
                                tint: tint(for: filter)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            if model.topPanelRoutes.isEmpty {
                Text("No tracked flight routes are ready yet.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.white.opacity(0.54))
                    .padding(.vertical, 4)
            } else {
                ForEach(model.topPanelRoutes) { route in
                    FlightRouteRow(model: model, route: route)
                }
            }
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if model.savedOpportunities.isEmpty == false {
                    Button {
                        model.boardSection = .routes
                        model.openBoard()
                    } label: {
                        CompactFlightActionButtonLabel(symbolName: "star", title: "Saved", trailingText: "\(model.savedOpportunities.count)")
                    }
                    .buttonStyle(FlightScoutSecondaryActionStyle())
                }

                Button {
                    model.exportCurrentFeed()
                } label: {
                    CompactFlightActionButtonLabel(symbolName: "arrow.down.circle", title: "Export")
                }
                .buttonStyle(FlightScoutSecondaryActionStyle())

                Button {
                    model.openRiskBoard()
                } label: {
                    CompactFlightActionButtonLabel(symbolName: "waveform.path.ecg", title: "Risk")
                }
                .buttonStyle(FlightScoutSecondaryActionStyle())

                Spacer(minLength: 0)
            }

            if !model.latestExports.isEmpty {
                Button {
                    model.revealLatestExports()
                } label: {
                    CompactFlightActionButtonLabel(symbolName: "arrow.up.right.square", title: "Reveal latest export")
                }
                .buttonStyle(FlightScoutSecondaryActionStyle())
            }
        }
    }

    private var dateSummary: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: model.settings.departureDate)) - \(formatter.string(from: model.settings.returnDate))"
    }

    private var trackedCount: Int {
        let count = model.settings.trackedDestinationQueries.count
        return max(count, model.snapshot?.routes.count ?? count)
    }

    private func tint(for filter: FlightFilter) -> Color {
        switch filter {
        case .all: return .blue
        case .cheapest: return .mint
        case .safest: return .green
        case .fastest: return .cyan
        case .trending: return .orange
        }
    }
}

private struct FlightRouteRow: View {
    @ObservedObject var model: FlightScoutAppModel
    let route: FlightRouteOpportunity

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                model.selectedRouteID = route.id
                model.openRoute(route)
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(routeAccentColor)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .center, spacing: 8) {
                            HStack(spacing: 6) {
                                Text(route.destination.compactLabel)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.95))
                                    .lineLimit(1)

                                if route.isNew {
                                    FlightScoutBadge(text: "New", tint: .blue)
                                }
                            }

                            Spacer(minLength: 0)

                            Text(model.primaryMetric(for: route))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(metricTint)
                                .lineLimit(1)
                        }

                        HStack(alignment: .center, spacing: 5) {
                            CompactRouteStatusDot(tint: statusTint)

                            Text(model.safetyBadgeText(for: route))
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(statusTint)
                                .lineLimit(1)

                            if let advisory = route.travelRisk.officialAdvisory {
                                CompactRouteSeparator()
                                FlightAdvisoryPill(advisory: advisory)
                            }

                            if compactMetaText.isEmpty == false {
                                CompactRouteSeparator()
                                Text(compactMetaText)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.46))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.026))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(routeAccentColor.opacity(0.14), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(FlightScoutMenuRowButtonStyle())

            Button {
                model.toggleSaved(route)
            } label: {
                Image(systemName: model.isSaved(route) ? "star.fill" : "star")
            }
            .buttonStyle(FlightScoutTrailingIconButtonStyle())
        }
    }

    private var routeAccentColor: Color {
        switch model.selectedFilter {
        case .all:
            return route.travelRisk.level.tintColor
        case .cheapest:
            return .mint
        case .safest:
            return model.isSaferPick(route) ? .green : route.travelRisk.level.tintColor
        case .fastest:
            return .cyan
        case .trending:
            return .orange
        }
    }

    private var metricTint: Color {
        switch model.selectedFilter {
        case .all:
            return Color.white.opacity(0.9)
        case .cheapest:
            return .mint
        case .safest:
            return model.isSaferPick(route) ? .green : .orange
        case .fastest:
            return .cyan
        case .trending:
            return .orange
        }
    }

    private var statusTint: Color {
        model.isSaferPick(route) ? .green : route.travelRisk.level.tintColor
    }

    private var compactMetaText: String {
        var parts: [String] = []

        switch model.selectedFilter {
        case .all:
            parts.append(route.bestQuote?.providerName ?? "Live fares")
            if let duration = route.bestQuote?.durationText {
                parts.append(duration)
            }
        case .cheapest:
            parts.append(route.bestQuote?.providerName ?? "Live fares")
            if let stops = route.bestQuote?.stopsText {
                parts.append(stops)
            }
        case .safest:
            if let stops = route.bestQuote?.stopsText {
                parts.append(stops)
            }
            if let provider = route.bestQuote?.providerName {
                parts.append(provider)
            }
        case .fastest:
            if let stops = route.bestQuote?.stopsText {
                parts.append(stops)
            }
            parts.append(route.bestPriceDisplay)
        case .trending:
            parts.append(route.isNew ? "New move" : "Live watch")
            if let provider = route.bestQuote?.providerName {
                parts.append(provider)
            }
        }

        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }
}

private struct CompactDateEditor: View {
    @ObservedObject var model: FlightScoutAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                DatePicker(
                    "Depart",
                    selection: Binding(
                        get: { model.settings.departureDate },
                        set: { model.setDateRange(departure: $0, returning: model.settings.returnDate) }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)

                DatePicker(
                    "Return",
                    selection: Binding(
                        get: { model.settings.returnDate },
                        set: { model.setDateRange(departure: model.settings.departureDate, returning: $0) }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
            }

            HStack(spacing: 6) {
                Button {
                    model.shiftDateRange(by: -1)
                } label: {
                    CompactFlightHeaderButton(symbolName: "chevron.left", title: "Earlier")
                }
                .buttonStyle(.plain)

                Button {
                    model.shiftDateRange(by: 1)
                } label: {
                    CompactFlightHeaderButton(symbolName: "chevron.right", title: "Later")
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
    }
}

private struct FlightRiskPill: View {
    let level: TravelRiskLevel

    var body: some View {
        Text(level.title)
            .font(.system(size: 9.5, weight: .semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(level.tintColor.opacity(0.11))
                    .overlay(
                        Capsule().stroke(level.tintColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundStyle(level.tintColor)
    }
}

private struct CompactFlightIconButton: View {
    let symbolName: String

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.82))
            .frame(width: 30, height: 30)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
    }
}

private struct CompactRouteStatusDot: View {
    let tint: Color

    var body: some View {
        Circle()
            .fill(tint)
            .frame(width: 6, height: 6)
    }
}

private struct CompactRouteSeparator: View {
    var body: some View {
        Text("•")
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.2))
    }
}

private struct FlightAdvisoryPill: View {
    let advisory: OfficialTravelAdvisory

    var body: some View {
        Text(advisory.compactLabel)
            .font(.system(size: 9.5, weight: .semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(advisory.level.tintColor.opacity(0.1))
                    .overlay(
                        Capsule().stroke(advisory.level.tintColor.opacity(0.18), lineWidth: 1)
                    )
            )
            .foregroundStyle(advisory.level.tintColor)
    }
}

private struct CompactFlightHeaderButton: View {
    let symbolName: String
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbolName)
                .font(.system(size: 10.5, weight: .semibold))
            Text(title)
                .font(.system(size: 10.5, weight: .semibold))
        }
        .foregroundStyle(Color.white.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

private struct CompactFlightActionButtonLabel: View {
    let symbolName: String
    let title: String
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbolName)
                .font(.system(size: 10.5, weight: .semibold))
            Text(title)
                .font(.system(size: 10.5, weight: .semibold))
            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.42))
            }
        }
    }
}

private struct FlightStatusBanner: View {
    let message: String
    let tint: Color
    let symbolName: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(tint)
                .lineLimit(2)
        }
    }
}
