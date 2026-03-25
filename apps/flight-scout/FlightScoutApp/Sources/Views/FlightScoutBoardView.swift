import SwiftUI

struct FlightScoutBoardView: View {
    @ObservedObject var model: FlightScoutAppModel

    var body: some View {
        ZStack {
            FlightScoutBackdrop()

            VStack(alignment: .leading, spacing: 12) {
                boardHeader

                Picker("", selection: $model.boardSection) {
                    ForEach(FlightBoardSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.small)

                switch model.boardSection {
                case .live:
                    liveSection
                case .routes:
                    routesSection
                case .risk:
                    riskSection
                case .settings:
                    settingsSection
                }
            }
            .padding(16)
        }
    }

    private var boardHeader: some View {
        FlightScoutCard {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Flight Scout Board")
                            .font(.system(size: 18, weight: .semibold))
                        FlightScoutBadge(text: model.snapshot?.rankingMode.label ?? "Watching", tint: .blue)
                    }

                    Text(model.panelTitle)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.95))

                    Text(model.primaryStatusMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.46))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Button("Refresh") {
                        model.refreshNow()
                    }
                    .buttonStyle(FlightScoutSecondaryActionStyle())

                    Button("Export Feed") {
                        model.exportCurrentFeed()
                    }
                    .buttonStyle(FlightScoutPrimaryActionStyle())
                }
            }
        }
    }

    private var liveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlightScoutCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Tracked Routes")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer(minLength: 0)
                        Text("\(model.newOpportunityCount) new")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(red: 0.47, green: 0.82, blue: 0.62))
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
                    }
                }
            }

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(model.routes) { route in
                        BoardRouteRow(model: model, route: route)
                    }
                }
            }
        }
    }

    private var routesSection: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                FlightScoutCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tracked Destinations")
                            .font(.system(size: 14, weight: .semibold))

                        HStack(spacing: 8) {
                            TextField("Add city or country", text: $model.draftDestinationQuery)
                                .textFieldStyle(.roundedBorder)

                            Button("Add") {
                                model.addTrackedDestination()
                            }
                            .buttonStyle(FlightScoutPrimaryActionStyle())
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                            ForEach(model.settings.trackedDestinationQueries, id: \.self) { query in
                                HStack {
                                    Text(query)
                                        .font(.system(size: 11.5, weight: .semibold))
                                    Spacer(minLength: 0)
                                    Button {
                                        model.removeTrackedDestination(query)
                                    } label: {
                                        Image(systemName: "xmark")
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(Color.white.opacity(0.55))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                }

                FlightScoutCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trip Window")
                            .font(.system(size: 14, weight: .semibold))

                        HStack(spacing: 12) {
                            DatePicker("Depart", selection: Binding(
                                get: { model.settings.departureDate },
                                set: { model.setDateRange(departure: $0, returning: model.settings.returnDate) }
                            ), displayedComponents: .date)

                            DatePicker("Return", selection: Binding(
                                get: { model.settings.returnDate },
                                set: { model.setDateRange(departure: model.settings.departureDate, returning: $0) }
                            ), displayedComponents: .date)
                        }

                        HStack(spacing: 12) {
                            Picker(
                                "Cabin",
                                selection: Binding(
                                    get: { model.settings.cabinClass },
                                    set: { value in model.updateSettings { $0.cabinClass = value } }
                                )
                            ) {
                                ForEach(FlightCabinClass.allCases) { cabin in
                                    Text(cabin.title).tag(cabin)
                                }
                            }
                            .pickerStyle(.segmented)

                            Stepper(
                                "Adults: \(model.settings.adults)",
                                value: Binding(
                                    get: { model.settings.adults },
                                    set: { value in model.updateSettings { $0.adults = max(1, value) } }
                                ),
                                in: 1...6
                            )
                        }
                    }
                }
            }
        }
    }

    private var riskSection: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if let route = model.selectedRoute {
                    FlightScoutCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(route.origin.city) -> \(route.destination.city)")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(route.travelRisk.summary)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white.opacity(0.46))
                                }

                                Spacer(minLength: 0)

                                VStack(alignment: .trailing, spacing: 6) {
                                    BoardSafetyPill(
                                        text: model.safetyBadgeText(for: route),
                                        tint: model.isSaferPick(route) ? .green : .orange
                                    )
                                    BoardRiskPill(level: route.travelRisk.level)
                                }
                            }

                            if let weather = route.travelRisk.weatherSummary {
                                HStack(spacing: 8) {
                                    FlightScoutPill(text: weather.summary, tint: .cyan)
                                    if let maxTemperatureC = weather.maxTemperatureC {
                                        FlightScoutPill(text: "\(Int(maxTemperatureC.rounded()))C max", tint: .orange)
                                    }
                                    if let precipitationChance = weather.precipitationChance {
                                        FlightScoutPill(text: "\(precipitationChance)% rain", tint: .blue)
                                    }
                                }
                            }

                            if let advisory = route.travelRisk.officialAdvisory {
                                HStack(spacing: 8) {
                                    BoardAdvisoryPill(advisory: advisory)
                                    if let updatedAt = advisory.lastUpdated {
                                        FlightScoutSourcePill(text: "Updated \(FlightScoutFormatting.shortTimestamp(from: updatedAt))")
                                    }
                                }

                                if advisory.reasons.isEmpty == false {
                                    HStack(spacing: 6) {
                                        ForEach(Array(advisory.reasons.prefix(3)), id: \.self) { reason in
                                            FlightScoutSourcePill(text: reason)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    FlightScoutCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Risk Breakdown")
                                .font(.system(size: 14, weight: .semibold))

                            ForEach(FlightRiskCategory.allCases) { category in
                                RiskBreakdownRow(
                                    title: category.title,
                                    tint: category.tintColor,
                                    value: route.travelRisk.breakdown.score(for: category)
                                )
                            }
                        }
                    }

                    FlightScoutCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Latest Headlines")
                                .font(.system(size: 14, weight: .semibold))

                            ForEach(route.travelRisk.headlines) { headline in
                                Button {
                                    model.openHeadline(headline)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            FlightScoutBadge(text: headline.category.title, tint: headline.category.tintColor)
                                            Text(headline.sourceName)
                                                .font(.system(size: 10.5, weight: .medium))
                                                .foregroundStyle(Color.white.opacity(0.42))
                                        }
                                        Text(headline.title)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color.white.opacity(0.95))
                                            .multilineTextAlignment(.leading)
                                        Text(headline.summary)
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.white.opacity(0.58))
                                            .multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(FlightScoutMenuRowButtonStyle())
                            }
                        }
                    }
                } else {
                    FlightScoutCard {
                        Text("Choose or track a route to see the expanded travel-risk analysis.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.56))
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                FlightScoutCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Flight + Risk Settings")
                            .font(.system(size: 14, weight: .semibold))

                        Toggle(
                            "Auto-refresh every minute",
                            isOn: Binding(
                                get: { model.settings.autoRefreshEnabled },
                                set: { value in model.updateSettings { $0.autoRefreshEnabled = value } }
                            )
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Price Provider Mode")
                                .font(.system(size: 11, weight: .semibold))
                            Picker(
                                "",
                                selection: Binding(
                                    get: { model.settings.priceProviderMode },
                                    set: { value in model.updateSettings { $0.priceProviderMode = value } }
                                )
                            ) {
                                ForEach(FlightPriceProviderMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Risk Source Density")
                                .font(.system(size: 11, weight: .semibold))
                            Picker(
                                "",
                                selection: Binding(
                                    get: { model.settings.densityMode },
                                    set: { value in model.updateSettings { $0.densityMode = value } }
                                )
                            ) {
                                ForEach(FlightSourceDensityMode.allCases) { density in
                                    Text(density.title).tag(density)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("OpenAI Model")
                                .font(.system(size: 11, weight: .semibold))
                            TextField(
                                "gpt-4.1-mini",
                                text: Binding(
                                    get: { model.settings.modelID },
                                    set: { value in model.updateSettings { $0.modelID = value } }
                                )
                            )
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                FlightScoutCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source Health")
                            .font(.system(size: 14, weight: .semibold))
                        ForEach(model.snapshot?.riskSourceHealth.prefix(18) ?? []) { health in
                            HStack {
                                Text(health.displayName)
                                    .font(.system(size: 11.5, weight: .medium))
                                Spacer(minLength: 0)
                                Text("\(health.itemCount)")
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.42))
                            }
                        }
                    }
                }
            }
        }
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

private struct BoardRouteRow: View {
    @ObservedObject var model: FlightScoutAppModel
    let route: FlightRouteOpportunity

    var body: some View {
        FlightScoutCard {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(route.travelRisk.level.tintColor.opacity(0.12))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "airplane")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(route.travelRisk.level.tintColor)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(route.origin.city) -> \(route.destination.city)")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer(minLength: 0)
                        BoardRiskPill(level: route.travelRisk.level)
                    }

                    HStack(spacing: 8) {
                        BoardSafetyPill(
                            text: model.safetyBadgeText(for: route),
                            tint: model.isSaferPick(route) ? .green : .orange
                        )
                        FlightScoutPill(text: route.bestPriceDisplay, tint: .mint)
                        if let advisory = route.travelRisk.officialAdvisory {
                            BoardAdvisoryPill(advisory: advisory)
                        }
                        if let provider = route.bestQuote?.providerName {
                            FlightScoutSourcePill(text: provider)
                        }
                        if let stops = route.bestQuote?.stopsText {
                            FlightScoutSourcePill(text: stops)
                        }
                    }

                    Text(route.travelRisk.summary)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if model.isSaferPick(route) {
                            Button("Book") {
                                model.openRoute(route)
                            }
                            .buttonStyle(FlightScoutPrimaryActionStyle())
                        } else {
                            Button("Book") {
                                model.openRoute(route)
                            }
                            .buttonStyle(FlightScoutSecondaryActionStyle())
                        }

                        Button("Select Risk") {
                            model.selectedRouteID = route.id
                            model.boardSection = .risk
                        }
                        .buttonStyle(FlightScoutSecondaryActionStyle())

                        Button(model.isSaved(route) ? "Unsave" : "Save") {
                            model.toggleSaved(route)
                        }
                        .buttonStyle(FlightScoutSecondaryActionStyle())
                    }
                }
            }
        }
    }
}

private struct RiskBreakdownRow: View {
    let title: String
    let tint: Color
    let value: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .frame(width: 88, alignment: .leading)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                    Capsule()
                        .fill(tint.opacity(0.75))
                        .frame(width: proxy.size.width * CGFloat(min(max(value, 0), 100)) / 100)
                }
            }
            .frame(height: 8)

            Text("\(value)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.56))
                .frame(width: 28, alignment: .trailing)
        }
    }
}

private struct BoardSafetyPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(tint.opacity(0.12))
                    .overlay(
                        Capsule().stroke(tint.opacity(0.22), lineWidth: 1)
                    )
            )
            .foregroundStyle(tint)
    }
}

private struct BoardRiskPill: View {
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

private struct BoardAdvisoryPill: View {
    let advisory: OfficialTravelAdvisory

    var body: some View {
        Text(advisory.compactLabel)
            .font(.system(size: 9.5, weight: .semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(advisory.level.tintColor.opacity(0.11))
                    .overlay(
                        Capsule().stroke(advisory.level.tintColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundStyle(advisory.level.tintColor)
    }
}
