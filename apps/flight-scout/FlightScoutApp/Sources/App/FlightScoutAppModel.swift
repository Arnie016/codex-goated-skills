import AppKit
import Foundation

@MainActor
final class FlightScoutAppModel: ObservableObject {
    @Published var settings = FlightScoutSettings()
    @Published var snapshot: TravelAnalysisSnapshot?
    @Published var savedOpportunities: [SavedFlightOpportunity] = []
    @Published var latestExports: [FlightExportArtifact] = []
    @Published var selectedFilter: FlightFilter = .all
    @Published var boardSection: FlightBoardSection = .live
    @Published var currentStepLabel = "Watching tracked routes."
    @Published var feedbackMessage: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var selectedRouteID: String?
    @Published var draftDestinationQuery = ""

    private let settingsStore = FlightScoutSettingsStore()
    private let engine = FlightScoutEngine()

    private struct RefreshPayload: Sendable {
        let snapshot: TravelAnalysisSnapshot
        let saved: [SavedFlightOpportunity]
        let exports: [FlightExportArtifact]
    }

    private var refreshTask: Task<RefreshPayload, Never>?
    private var autoRefreshTask: Task<Void, Never>?
    private var clearMessageTask: Task<Void, Never>?
    private var refreshToken = UUID()

    init() {
        Task {
            let loadedSettings = await settingsStore.load()
            let saved = await engine.loadSavedOpportunities()
            let exports = await engine.latestExports()

            await MainActor.run {
                self.settings = loadedSettings
                self.savedOpportunities = saved
                self.latestExports = exports
            }

            await refresh(force: true)
            startAutoRefreshLoop()
        }
    }

    deinit {
        refreshTask?.cancel()
        autoRefreshTask?.cancel()
        clearMessageTask?.cancel()
    }

    var region: VPNRegion {
        snapshot?.region ?? .fallback()
    }

    var origin: FlightPlace? {
        snapshot?.origin
    }

    var routes: [FlightRouteOpportunity] {
        guard let snapshot else { return [] }
        switch selectedFilter {
        case .all:
            return snapshot.routes
        case .cheapest:
            return snapshot.routes.sorted { ($0.bestQuote?.totalPrice ?? .greatestFiniteMagnitude) < ($1.bestQuote?.totalPrice ?? .greatestFiniteMagnitude) }
        case .safest:
            let qualified = snapshot.routes.filter(FlightSafetyEvaluator.qualifies)
            let pool = qualified.isEmpty ? snapshot.routes : qualified
            return pool.sorted { FlightSafetyEvaluator.safetyScore(for: $0) > FlightSafetyEvaluator.safetyScore(for: $1) }
        case .fastest:
            return snapshot.routes.sorted {
                let left = durationHours(from: $0.bestQuote?.durationText)
                let right = durationHours(from: $1.bestQuote?.durationText)
                return left < right
            }
        case .trending:
            return snapshot.routes.sorted { $0.rankingScore > $1.rankingScore }
        }
    }

    var topPanelRoutes: [FlightRouteOpportunity] {
        Array(routes.prefix(3))
    }

    var selectedRoute: FlightRouteOpportunity? {
        routes.first(where: { $0.id == selectedRouteID }) ?? routes.first
    }

    var panelTitle: String {
        origin.map { "\($0.compactLabel) outbound" } ?? region.displayTitle
    }

    var panelSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let departure = formatter.string(from: settings.departureDate)
        let returning = formatter.string(from: settings.returnDate)
        let mode = snapshot?.rankingMode.label ?? "Watching"
        return "\(departure) - \(returning) • \(effectiveTrackedCount) tracked • \(mode)"
    }

    var liveSourceCount: Int {
        snapshot?.riskSourceHealth.count ?? 0
    }

    var newOpportunityCount: Int {
        snapshot?.newOpportunityCount ?? 0
    }

    var saferOpportunityCount: Int {
        snapshot?.routes.filter(FlightSafetyEvaluator.qualifies).count ?? 0
    }

    var effectiveTrackedCount: Int {
        let explicit = settings.trackedDestinationQueries.count
        if explicit > 0 { return explicit }
        if let routeCount = snapshot?.routes.count, routeCount > 0 { return routeCount }
        return 5
    }

    var menuBarSymbolName: String {
        if isLoading {
            return "airplane.circle.fill"
        }
        if errorMessage != nil {
            return "exclamationmark.triangle.fill"
        }
        if newOpportunityCount > 0 {
            return "airplane.departure"
        }
        return "airplane"
    }

    var primaryStatusMessage: String {
        if isLoading { return currentStepLabel }
        if selectedFilter == .safest, let snapshot {
            let safeCount = snapshot.routes.filter(FlightSafetyEvaluator.qualifies).count
            if safeCount == 0 {
                return "No route clears the safer-flight bar right now. Showing the lowest-risk fallbacks."
            }
            return "\(safeCount) routes currently clear the safer-flight bar."
        }
        return snapshot?.statusMessage ?? "Tracking live route prices and travel risk."
    }

    func isSaferPick(_ route: FlightRouteOpportunity) -> Bool {
        FlightSafetyEvaluator.qualifies(route)
    }

    func safetyBadgeText(for route: FlightRouteOpportunity) -> String {
        FlightSafetyEvaluator.badgeText(for: route)
    }

    func safetyScore(for route: FlightRouteOpportunity) -> Int {
        FlightSafetyEvaluator.safetyScore(for: route)
    }

    func primaryMetric(for route: FlightRouteOpportunity) -> String {
        switch selectedFilter {
        case .all, .trending:
            return route.bestPriceDisplay
        case .cheapest:
            return route.bestPriceDisplay
        case .safest:
            return route.travelRisk.officialAdvisory?.summary ?? route.travelRisk.level.title
        case .fastest:
            return route.bestQuote?.durationText ?? "Live duration"
        }
    }

    func secondaryMetric(for route: FlightRouteOpportunity) -> String {
        switch selectedFilter {
        case .all, .trending:
            return route.bestQuote?.providerName ?? "Live fares"
        case .cheapest:
            return route.bestQuote?.providerName ?? "Live fares"
        case .safest:
            return route.bestQuote?.stopsText ?? "Check route"
        case .fastest:
            return route.bestQuote?.stopsText ?? "Stops vary"
        }
    }

    func summaryLine(for route: FlightRouteOpportunity) -> String {
        switch selectedFilter {
        case .all:
            return defaultRouteSummary(for: route)
        case .cheapest:
            if let quote = route.bestQuote {
                return "\(quote.priceDisplay) is the lowest live fare signal."
            }
            return "Open the live compare fares for this route."
        case .safest:
            if isSaferPick(route) {
                return "Clears the safer-flight bar with calmer advisory, route, and weather checks."
            }
            return "Needs a manual risk check before booking."
        case .fastest:
            if let quote = route.bestQuote {
                return "\(quote.durationText) • \(quote.stopsText) • \(quote.providerName)"
            }
            return "Open live route duration details."
        case .trending:
            if route.isNew {
                return "New route signal with live pricing or availability movement."
            }
            return defaultRouteSummary(for: route)
        }
    }

    func shiftDateRange(by days: Int) {
        let departure = Calendar.current.date(byAdding: .day, value: days, to: settings.departureDate) ?? settings.departureDate
        let returning = Calendar.current.date(byAdding: .day, value: days, to: settings.returnDate) ?? settings.returnDate
        setDateRange(departure: departure, returning: returning)
    }

    func refresh(force: Bool = false) async {
        refreshTask?.cancel()
        let refreshToken = UUID()
        self.refreshToken = refreshToken
        isLoading = true
        currentStepLabel = force ? "Refreshing live routes..." : "Checking tracked routes..."

        let settingsSnapshot = settings
        let engine = self.engine

        let task = Task { [settingsSnapshot, force] in
            async let snapshot = engine.refresh(settings: settingsSnapshot, force: force)
            async let saved = engine.loadSavedOpportunities()
            async let exports = engine.latestExports()
            return RefreshPayload(
                snapshot: await snapshot,
                saved: await saved,
                exports: await exports
            )
        }
        refreshTask = task
        let payload = await task.value

        guard self.refreshToken == refreshToken, !Task.isCancelled else { return }

        snapshot = payload.snapshot
        savedOpportunities = payload.saved
        latestExports = payload.exports
        selectedRouteID = selectedRouteID ?? payload.snapshot.routes.first?.id
        isLoading = false
        currentStepLabel = "Live routes ready"
        feedbackMessage = nil
        errorMessage = nil
    }

    func refreshNow() {
        Task {
            await refresh(force: true)
        }
    }

    func updateSettings(_ mutate: (inout FlightScoutSettings) -> Void) {
        mutate(&settings)
        let snapshot = settings
        Task {
            await settingsStore.save(snapshot)
            await refresh(force: true)
        }
    }

    func addTrackedDestination() {
        let trimmed = draftDestinationQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateSettings { settings in
            if settings.trackedDestinationQueries.contains(trimmed) == false {
                settings.trackedDestinationQueries.append(trimmed)
            }
        }
        draftDestinationQuery = ""
        setFeedback("Added \(trimmed) to tracked routes.")
    }

    func removeTrackedDestination(_ query: String) {
        updateSettings { settings in
            settings.trackedDestinationQueries.removeAll { $0 == query }
        }
    }

    func setDateRange(departure: Date, returning: Date) {
        updateSettings { settings in
            settings.departureDate = departure
            settings.returnDate = max(returning, departure)
        }
    }

    func toggleSaved(_ opportunity: FlightRouteOpportunity) {
        Task {
            savedOpportunities = await engine.toggleSave(opportunity)
        }
    }

    func removeSaved(_ opportunity: SavedFlightOpportunity) {
        Task {
            savedOpportunities = await engine.removeSavedOpportunity(id: opportunity.id)
        }
    }

    func isSaved(_ opportunity: FlightRouteOpportunity) -> Bool {
        savedOpportunities.contains(where: { $0.id == opportunity.id })
    }

    func openBoard() {
        boardSection = .live
        NotificationCenter.default.post(name: .flightScoutOpenBoard, object: nil)
    }

    func openRiskBoard() {
        boardSection = .risk
        NotificationCenter.default.post(name: .flightScoutOpenBoard, object: nil)
    }

    func openSettingsBoard() {
        boardSection = .settings
        NotificationCenter.default.post(name: .flightScoutOpenBoard, object: nil)
    }

    func openRoute(_ opportunity: FlightRouteOpportunity) {
        NSWorkspace.shared.open(opportunity.bookingURL)
    }

    func openQuote(_ quote: FlightQuote) {
        NSWorkspace.shared.open(quote.bookingURL)
    }

    func openHeadline(_ headline: TravelRiskHeadline) {
        NSWorkspace.shared.open(headline.articleURL)
    }

    func openSavedBooking(_ opportunity: SavedFlightOpportunity) {
        NSWorkspace.shared.open(opportunity.bookingURL)
    }

    func exportCurrentFeed() {
        Task {
            do {
                latestExports = try await engine.exportRoutes(routes, title: "Flight Scout Feed")
                setFeedback("Exported the current tracked feed.")
            } catch {
                setError("Could not export the current feed.")
            }
        }
    }

    func exportSavedDigest() {
        Task {
            do {
                latestExports = try await engine.exportSavedRoutes(title: "Flight Scout Saved")
                setFeedback("Exported saved routes.")
            } catch {
                setError("Could not export saved routes.")
            }
        }
    }

    func revealLatestExports() {
        guard let first = latestExports.first else { return }
        NSWorkspace.shared.activateFileViewerSelecting([first.fileURL])
    }

    func openLatestExport() {
        guard let first = latestExports.first else { return }
        NSWorkspace.shared.open(first.fileURL)
    }

    private func startAutoRefreshLoop() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { return }
                if settings.autoRefreshEnabled {
                    await refresh(force: false)
                }
            }
        }
    }

    private func durationHours(from text: String?) -> Int {
        guard let text else { return .max }
        let nsText = text as NSString
        let regex = try? NSRegularExpression(pattern: "([0-9]{1,2})\\s*h", options: .caseInsensitive)
        guard let match = regex?.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) else {
            return .max
        }
        return Int(nsText.substring(with: match.range(at: 1))) ?? .max
    }

    private func setFeedback(_ message: String) {
        feedbackMessage = message
        errorMessage = nil
        clearMessageLater()
    }

    private func setError(_ message: String) {
        errorMessage = message
        feedbackMessage = nil
        clearMessageLater()
    }

    private func clearMessageLater() {
        clearMessageTask?.cancel()
        clearMessageTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            feedbackMessage = nil
            errorMessage = nil
        }
    }

    private func defaultRouteSummary(for route: FlightRouteOpportunity) -> String {
        route.patternSignals.first?.summary ?? route.travelRisk.summary
    }
}

enum FlightSafetyEvaluator {
    static func qualifies(_ route: FlightRouteOpportunity) -> Bool {
        guard route.bestQuote != nil else { return false }
        guard route.travelRisk.level == .low || route.travelRisk.level == .guarded else { return false }
        guard route.travelRisk.score <= 40 else { return false }
        guard route.travelRisk.breakdown.security < 26 else { return false }
        guard route.travelRisk.breakdown.aviation < 28 else { return false }
        guard route.travelRisk.breakdown.civil < 22 else { return false }
        guard route.travelRisk.breakdown.disruption < 26 else { return false }
        guard route.bestQuote?.confidenceScore ?? 0 >= 55 else { return false }

        if let advisory = route.travelRisk.officialAdvisory, advisory.level.isSaferEligible == false {
            return false
        }

        let stops = route.bestQuote?.stopsText.lowercased() ?? ""
        if !(stops.contains("direct") || stops.contains("1 stop") || stops.contains("1-stop")) {
            return false
        }

        if let weather = route.travelRisk.weatherSummary {
            if let precipitationChance = weather.precipitationChance, precipitationChance >= 70 {
                return false
            }
            if let maxWindKph = weather.maxWindKph, maxWindKph >= 35 {
                return false
            }
            if let code = weather.weatherCode, [95, 96, 99].contains(code) {
                return false
            }
        }

        return true
    }

    static func badgeText(for route: FlightRouteOpportunity) -> String {
        qualifies(route) ? "Safer pick" : "Review risk"
    }

    static func safetyScore(for route: FlightRouteOpportunity) -> Int {
        var score = 100 - route.travelRisk.score

        if let quote = route.bestQuote {
            score += quote.stopsText.localizedCaseInsensitiveContains("Direct") ? 12 : 4
            score += min(quote.confidenceScore / 8, 10)
        }

        if let advisory = route.travelRisk.officialAdvisory {
            switch advisory.level {
            case .level1:
                score += 12
            case .level2:
                score += 6
            case .level3:
                score -= 12
            case .level4:
                score -= 24
            }
        }

        score -= min(route.travelRisk.breakdown.security / 3, 15)
        score -= min(route.travelRisk.breakdown.aviation / 3, 12)
        score -= min(route.travelRisk.breakdown.civil / 3, 10)
        return score
    }
}
