import Foundation

actor FlightScoutEngine {
    private let regionService: VPNRegionService
    private let resolver: FlightRouteResolverService
    private let priceSearchService: FlightPriceSearchService
    private let riskFeedService: FlightRiskFeedService
    private let advisoryService: OfficialTravelAdvisoryService
    private let rankingService: FlightScoutRankingService
    private let persistenceStore: FlightScoutPersistenceStore
    private let weatherService: FlightWeatherService
    private var lastRegion: VPNRegion?

    init(
        regionService: VPNRegionService = VPNRegionService(),
        resolver: FlightRouteResolverService = FlightRouteResolverService(),
        priceSearchService: FlightPriceSearchService = FlightPriceSearchService(),
        riskFeedService: FlightRiskFeedService = FlightRiskFeedService(),
        advisoryService: OfficialTravelAdvisoryService = OfficialTravelAdvisoryService(),
        rankingService: FlightScoutRankingService = FlightScoutRankingService(),
        persistenceStore: FlightScoutPersistenceStore = FlightScoutPersistenceStore(),
        weatherService: FlightWeatherService = FlightWeatherService()
    ) {
        self.regionService = regionService
        self.resolver = resolver
        self.priceSearchService = priceSearchService
        self.riskFeedService = riskFeedService
        self.advisoryService = advisoryService
        self.rankingService = rankingService
        self.persistenceStore = persistenceStore
        self.weatherService = weatherService
    }

    func refresh(settings: FlightScoutSettings, force: Bool = false, now: Date = Date()) async -> TravelAnalysisSnapshot {
        try? await persistenceStore.ensureDirectories()

        let region = (try? await regionService.detectCurrentRegion()) ?? VPNRegion.fallback()
        let origin = resolver.resolveOrigin(for: region)
        let trackedQueries = sanitizedQueries(settings: settings, region: region)
        let destinations = trackedQueries.compactMap { resolver.resolveDestination(query: $0) }
        let routeTargets = Array(NSOrderedSet(array: destinations).array as? [FlightPlace] ?? destinations).prefix(6)

        var riskCache = await persistenceStore.loadRiskCache()
        var seenHistory = await persistenceStore.loadSeenHistory()
        var opportunities: [FlightRouteOpportunity] = []
        var sourceHealth: [TravelRiskSourceHealth] = []
        var statusMessages: [String] = []

        let selectedSources = FlightScoutSourceCatalog.sources(for: settings.densityMode)

        for destination in routeTargets {
            let query = FlightSearchQuery(
                origin: origin,
                destination: destination,
                departureDate: settings.departureDate,
                returnDate: settings.returnDate,
                cabinClass: settings.cabinClass,
                adults: settings.adults,
                currencyCode: settings.preferredCurrency
            )
            let routeID = makeRouteID(origin: origin, destination: destination, departureDate: settings.departureDate, returnDate: settings.returnDate)

            async let searchResultTask = priceSearchService.search(query: query, settings: settings, now: now)
            async let weatherTask = weatherService.fetch(destination: destination, departureDate: settings.departureDate, returnDate: settings.returnDate)
            async let advisoryTask = advisoryService.advisory(for: destination, now: now)

            let dueSources = force || regionChanged(current: region)
                ? selectedSources
                : FlightRiskFeedService.dueSources(routeID: routeID, sources: selectedSources, cache: riskCache, now: now)

            for batch in dueSources.chunked(into: 8) {
                let results = await withTaskGroup(of: FlightRiskFeedService.RiskFetchResult.self, returning: [FlightRiskFeedService.RiskFetchResult].self) { group in
                    for source in batch {
                        group.addTask {
                            await self.riskFeedService.fetch(
                                source: source,
                                origin: origin,
                                destination: destination,
                                departureDate: settings.departureDate,
                                returnDate: settings.returnDate,
                                now: now
                            )
                        }
                    }

                    var output: [FlightRiskFeedService.RiskFetchResult] = []
                    for await result in group {
                        output.append(result)
                    }
                    return output
                }

                for result in results {
                    let cacheKey = "\(routeID)::\(result.source.id)"
                    riskCache[cacheKey] = TravelRiskSourceCacheEntry(
                        sourceID: cacheKey,
                        fingerprint: result.fingerprint,
                        lastFetchedAt: now,
                        headlines: result.headlines,
                        failureCount: result.failureCount
                    )
                }
            }

            let searchResult = await searchResultTask
            let weather = await weatherTask
            let advisory = await advisoryTask
            if let status = searchResult.statusMessage {
                statusMessages.append(status)
            }

            let headlines = selectedSources.flatMap { source in
                riskCache["\(routeID)::\(source.id)"]?.headlines ?? []
            }

            let risk = buildRiskSnapshot(
                routeID: routeID,
                destination: destination,
                headlines: headlines,
                advisory: advisory,
                weather: weather,
                now: now
            )

            let patterns = buildPatternSignals(
                quotes: searchResult.quotes,
                risk: risk,
                destination: destination
            )

            let firstSeen = seenHistory[routeID]
            opportunities.append(
                FlightRouteOpportunity(
                    id: routeID,
                    origin: origin,
                    destination: destination,
                    queryText: destination.city,
                    quotes: searchResult.quotes,
                    bestQuote: bestQuote(from: searchResult.quotes),
                    patternSignals: patterns,
                    travelRisk: risk,
                    rankingScore: 0,
                    rankingMode: .deterministicFallback,
                    firstSeenAt: firstSeen ?? now,
                    fetchedAt: now,
                    isNew: firstSeen == nil
                )
            )

            let routeHealth = FlightRiskFeedService.hydrateHealth(routeID: routeID, sources: selectedSources, cache: riskCache).map { health in
                TravelRiskSourceHealth(
                    id: health.id,
                    displayName: "\(destination.city) • \(health.displayName)",
                    category: health.category,
                    refreshTier: health.refreshTier,
                    lastFetchedAt: health.lastFetchedAt,
                    itemCount: health.itemCount,
                    failureCount: health.failureCount
                )
            }
            sourceHealth.append(contentsOf: routeHealth.prefix(12))
        }

        let (rankingMode, ranked) = await rankingService.rank(opportunities: opportunities, region: region, settings: settings)

        for item in ranked {
            seenHistory[item.id] = seenHistory[item.id] ?? now
        }
        seenHistory = await persistenceStore.pruneSeenHistory(seenHistory, now: now)
        try? await persistenceStore.saveRiskCache(riskCache)
        try? await persistenceStore.saveSeenHistory(seenHistory)
        lastRegion = region

        let statusMessage = ranked.isEmpty
            ? "No tracked routes are available yet."
            : statusMessages.first

        return TravelAnalysisSnapshot(
            region: region,
            origin: origin,
            routes: ranked,
            riskSourceHealth: sourceHealth.sorted { $0.displayName < $1.displayName },
            rankingMode: rankingMode,
            lastUpdated: now,
            newOpportunityCount: ranked.filter(\.isNew).count,
            statusMessage: statusMessage
        )
    }

    func loadSavedOpportunities() async -> [SavedFlightOpportunity] {
        await persistenceStore.loadSavedOpportunities().sorted { $0.savedAt > $1.savedAt }
    }

    func toggleSave(_ opportunity: FlightRouteOpportunity) async -> [SavedFlightOpportunity] {
        var saved = await persistenceStore.loadSavedOpportunities()
        if let index = saved.firstIndex(where: { $0.id == opportunity.id }) {
            saved.remove(at: index)
        } else {
            saved.insert(SavedFlightOpportunity(opportunity: opportunity), at: 0)
        }
        try? await persistenceStore.saveSavedOpportunities(saved)
        return saved.sorted { $0.savedAt > $1.savedAt }
    }

    func removeSavedOpportunity(id: String) async -> [SavedFlightOpportunity] {
        var saved = await persistenceStore.loadSavedOpportunities()
        saved.removeAll { $0.id == id }
        try? await persistenceStore.saveSavedOpportunities(saved)
        return saved.sorted { $0.savedAt > $1.savedAt }
    }

    func exportSavedRoutes(title: String) async throws -> [FlightExportArtifact] {
        try await persistenceStore.exportDigest(routes: loadSavedOpportunities(), title: title)
    }

    func exportRoutes(_ routes: [FlightRouteOpportunity], title: String) async throws -> [FlightExportArtifact] {
        let shaped = routes.map { SavedFlightOpportunity(opportunity: $0, savedAt: Date()) }
        return try await persistenceStore.exportDigest(routes: shaped, title: title)
    }

    func latestExports() async -> [FlightExportArtifact] {
        await persistenceStore.latestExports()
    }

    private func bestQuote(from quotes: [FlightQuote]) -> FlightQuote? {
        quotes.sorted { lhs, rhs in
            switch (lhs.totalPrice, rhs.totalPrice) {
            case let (l?, r?):
                if l == r { return lhs.confidenceScore > rhs.confidenceScore }
                return l < r
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.confidenceScore > rhs.confidenceScore
            }
        }.first
    }

    private func buildPatternSignals(
        quotes: [FlightQuote],
        risk: TravelRiskSnapshot,
        destination: FlightPlace
    ) -> [FlightPatternSignal] {
        var signals: [FlightPatternSignal] = []

        if let cheapest = quotes.compactMap(\.totalPrice).min(), let currency = quotes.first(where: { $0.totalPrice == cheapest })?.currencyCode {
            signals.append(
                FlightPatternSignal(
                    label: "Cheapest now",
                    summary: "\(FlightScoutFormatting.currencyString(amount: cheapest, currencyCode: currency)) is the lowest live signal."
                )
            )
        }

        if let direct = quotes.first(where: { $0.stopsText.localizedCaseInsensitiveContains("Direct") }) {
            signals.append(
                FlightPatternSignal(
                    label: "Direct angle",
                    summary: "\(direct.providerName) is surfacing a direct-style route."
                )
            )
        }

        signals.append(
            FlightPatternSignal(
                label: "Risk view",
                summary: "\(destination.city) is \(risk.level.title.lowercased()) risk right now."
            )
        )

        return Array(signals.prefix(3))
    }

    private func buildRiskSnapshot(
        routeID: String,
        destination: FlightPlace,
        headlines: [TravelRiskHeadline],
        advisory: OfficialTravelAdvisory?,
        weather: TravelWeatherSummary?,
        now: Date
    ) -> TravelRiskSnapshot {
        let normalizedHeadlines = normalizedHeadlines(from: headlines)
        var breakdown = TravelRiskBreakdown(
            disruption: normalizedCategoryScore(.disruption, headlines: normalizedHeadlines),
            weather: normalizedCategoryScore(.weather, headlines: normalizedHeadlines),
            security: normalizedCategoryScore(.security, headlines: normalizedHeadlines),
            civil: normalizedCategoryScore(.civil, headlines: normalizedHeadlines),
            health: normalizedCategoryScore(.health, headlines: normalizedHeadlines),
            migration: normalizedCategoryScore(.migration, headlines: normalizedHeadlines),
            trade: normalizedCategoryScore(.trade, headlines: normalizedHeadlines),
            aviation: normalizedCategoryScore(.aviation, headlines: normalizedHeadlines)
        )

        if let weather {
            breakdown.weather = min(22, breakdown.weather + weatherRiskBoost(weather))
        }

        if let advisory {
            breakdown.security = min(30, breakdown.security + advisory.level.riskBoost)
        }

        var composite = min(
            100,
            breakdown.disruption / 2
                + breakdown.weather / 2
                + breakdown.security
                + breakdown.civil / 2
                + breakdown.health / 2
                + breakdown.migration / 4
                + breakdown.trade / 4
                + (breakdown.aviation * 2 / 3)
        )

        composite = normalizedCompositeScore(
            composite,
            advisory: advisory,
            breakdown: breakdown,
            headlines: normalizedHeadlines
        )
        let level = FlightScoutFormatting.deepRiskLabel(for: composite)
        let summary = riskSummary(level: level, destination: destination, breakdown: breakdown, advisory: advisory, weather: weather, headlines: normalizedHeadlines)

        return TravelRiskSnapshot(
            score: composite,
            level: level,
            summary: summary,
            breakdown: breakdown,
            officialAdvisory: advisory,
            weatherSummary: weather,
            headlines: Array(normalizedHeadlines.sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }.prefix(10)),
            rankingMode: .deterministicFallback,
            lastUpdated: now
        )
    }

    private func severityBoost(for headline: TravelRiskHeadline) -> Int {
        let text = "\(headline.title) \(headline.summary)".lowercased()
        var score = max(2, headline.weight / 14)

        let critical = ["terror", "attack", "explosion", "missile", "war", "dead", "fatal", "severe", "closure", "ground stop"]
        let elevated = ["strike", "protest", "storm", "flood", "disruption", "cancel", "warning", "security", "evacuation", "outbreak"]
        let mild = ["delay", "queue", "inspection", "monitoring", "advisory", "watch", "review"]

        if critical.contains(where: text.contains) {
            score += 8
        } else if elevated.contains(where: text.contains) {
            score += 4
        } else if mild.contains(where: text.contains) {
            score += 2
        }

        if let publishedAt = headline.publishedAt {
            let hours = Date().timeIntervalSince(publishedAt) / 3600
            if hours < 24 {
                score += 2
            }
        }

        return score
    }

    private func weatherRiskBoost(_ weather: TravelWeatherSummary) -> Int {
        var score = 0
        if let precip = weather.precipitationChance, precip >= 70 { score += 18 }
        if let wind = weather.maxWindKph, wind >= 35 { score += 14 }
        switch weather.weatherCode {
        case 95, 96, 99:
            score += 20
        case 71, 73, 75, 77, 80, 81, 82:
            score += 10
        case 45, 48:
            score += 8
        default:
            break
        }
        return score
    }

    private func riskSummary(
        level: TravelRiskLevel,
        destination: FlightPlace,
        breakdown: TravelRiskBreakdown,
        advisory: OfficialTravelAdvisory?,
        weather: TravelWeatherSummary?,
        headlines: [TravelRiskHeadline]
    ) -> String {
        let leadingCategory = FlightRiskCategory.allCases.max { lhs, rhs in
            breakdown.score(for: lhs) < breakdown.score(for: rhs)
        } ?? .security
        let topHeadline = headlines.first?.title ?? "No major headline spike"
        let weatherNote = weather?.summary ?? "Weather calm"
        let advisoryNote: String
        if let advisory {
            advisoryNote = "\(advisory.authorityName) advisory \(advisory.level.shortLabel): \(advisory.level.summary)."
        } else {
            advisoryNote = "No official advisory pulled yet."
        }
        return "\(destination.city) is \(level.title.lowercased()) risk. \(advisoryNote) \(weatherNote). Top signal: \(leadingCategory.title.lowercased()). \(topHeadline)"
    }

    private func normalizedHeadlines(from headlines: [TravelRiskHeadline]) -> [TravelRiskHeadline] {
        var seen = Set<String>()
        return headlines.filter { headline in
            let key = normalizedHeadlineKey(headline)
            return seen.insert(key).inserted
        }
    }

    private func normalizedHeadlineKey(_ headline: TravelRiskHeadline) -> String {
        "\(headline.category.rawValue)|\(headline.title.lowercased())"
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9|]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedCategoryScore(_ category: FlightRiskCategory, headlines: [TravelRiskHeadline]) -> Int {
        let cap: Int
        switch category {
        case .disruption: cap = 18
        case .weather: cap = 18
        case .security: cap = 26
        case .civil: cap = 18
        case .health: cap = 14
        case .migration: cap = 10
        case .trade: cap = 10
        case .aviation: cap = 20
        }

        let relevant = headlines
            .filter { $0.category == category }
            .sorted { lhs, rhs in
                let leftScore = severityBoost(for: lhs)
                let rightScore = severityBoost(for: rhs)
                if leftScore == rightScore {
                    return (lhs.publishedAt ?? .distantPast) > (rhs.publishedAt ?? .distantPast)
                }
                return leftScore > rightScore
            }
            .prefix(3)

        let total = relevant.enumerated().reduce(into: 0) { result, item in
            let divisor = max(1, item.offset + 1)
            result += max(1, severityBoost(for: item.element) / divisor)
        }

        return min(cap, total)
    }

    private func normalizedCompositeScore(
        _ composite: Int,
        advisory: OfficialTravelAdvisory?,
        breakdown: TravelRiskBreakdown,
        headlines: [TravelRiskHeadline]
    ) -> Int {
        var value = composite
        let criticalHeadlinePresent = headlines.contains { headline in
            let text = "\(headline.title) \(headline.summary)".lowercased()
            return ["terror", "attack", "missile", "war", "ground stop", "airport closure"].contains(where: text.contains)
        }

        if let advisory {
            switch advisory.level {
            case .level1:
                if !criticalHeadlinePresent && breakdown.security < 18 && breakdown.aviation < 16 {
                    value = min(value, 34)
                }
            case .level2:
                if !criticalHeadlinePresent && breakdown.security < 22 && breakdown.aviation < 18 {
                    value = min(value, 48)
                }
            case .level3:
                value = max(value, 58)
            case .level4:
                value = max(value, 76)
            }
        }

        return min(max(value, 0), 100)
    }

    private func sanitizedQueries(settings: FlightScoutSettings, region: VPNRegion) -> [String] {
        let queries = settings.trackedDestinationQueries.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if queries.isEmpty {
            return resolver.defaultTrackedQueries(for: region)
        }
        return queries
    }

    private func regionChanged(current: VPNRegion) -> Bool {
        defer { lastRegion = current }
        return lastRegion?.countryCode != current.countryCode || lastRegion?.city != current.city
    }

    private func makeRouteID(origin: FlightPlace, destination: FlightPlace, departureDate: Date, returnDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return "\(origin.iataCode)-\(destination.iataCode)-\(formatter.string(from: departureDate))-\(formatter.string(from: returnDate))"
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return isEmpty ? [] : [self] }
        return stride(from: 0, to: count, by: size).map { index in
            Array(self[index ..< Swift.min(index + size, count)])
        }
    }
}
