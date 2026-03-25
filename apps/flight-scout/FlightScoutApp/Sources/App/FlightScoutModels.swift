import Foundation
import SwiftUI

struct VPNRegion: Codable, Equatable, Hashable, Sendable {
    let ipAddress: String
    let city: String
    let regionName: String
    let countryCode: String
    let countryName: String
    let timezone: String
    let latitude: Double?
    let longitude: Double?

    var flagEmoji: String {
        let base: UInt32 = 127397
        return countryCode.uppercased().unicodeScalars.compactMap { scalar in
            UnicodeScalar(base + scalar.value)
        }.map(String.init).joined()
    }

    var displayTitle: String {
        if !city.isEmpty {
            return "\(flagEmoji) \(city), \(countryCode)"
        }
        return "\(flagEmoji) \(countryName)"
    }

    var displaySubtitle: String {
        let location = [countryName, timezone].filter { !$0.isEmpty }.joined(separator: " • ")
        return location.isEmpty ? "Current VPN region" : location
    }

    static func fallback(locale: Locale = .current) -> VPNRegion {
        let countryCode = locale.region?.identifier ?? "US"
        let countryName = locale.localizedString(forRegionCode: countryCode) ?? "United States"

        return VPNRegion(
            ipAddress: "",
            city: "",
            regionName: "",
            countryCode: countryCode.uppercased(),
            countryName: countryName,
            timezone: TimeZone.current.identifier,
            latitude: nil,
            longitude: nil
        )
    }
}

struct FlightPlace: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let iataCode: String
    let city: String
    let countryCode: String
    let countryName: String
    let airportName: String
    let latitude: Double?
    let longitude: Double?
    let aliases: [String]

    var title: String {
        "\(city), \(countryCode)"
    }

    var subtitle: String {
        "\(airportName) • \(iataCode)"
    }

    var flagEmoji: String {
        let base: UInt32 = 127397
        return countryCode.uppercased().unicodeScalars.compactMap { scalar in
            UnicodeScalar(base + scalar.value)
        }.map(String.init).joined()
    }

    var compactLabel: String {
        "\(flagEmoji) \(city)"
    }
}

enum FlightCabinClass: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case economy
    case premiumEconomy
    case business
    case first

    var id: String { rawValue }

    var title: String {
        switch self {
        case .economy: return "Economy"
        case .premiumEconomy: return "Premium"
        case .business: return "Business"
        case .first: return "First"
        }
    }
}

enum FlightPriceProviderMode: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case auto
    case publicSignalsOnly
    case serpAPI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "Auto"
        case .publicSignalsOnly: return "Public"
        case .serpAPI: return "SerpAPI"
        }
    }
}

enum FlightSourceDensityMode: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case essential
    case full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .essential: return "Essential"
        case .full: return "Full"
        }
    }
}

enum FlightBoardSection: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case live
    case routes
    case risk
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: return "Live"
        case .routes: return "Routes"
        case .risk: return "Risk"
        case .settings: return "Settings"
        }
    }
}

enum FlightFilter: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case all
    case cheapest
    case safest
    case fastest
    case trending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .cheapest: return "Cheapest"
        case .safest: return "Safest"
        case .fastest: return "Fastest"
        case .trending: return "Trending"
        }
    }
}

enum FlightRefreshTier: String, Codable, Hashable, Sendable {
    case fast
    case medium
    case slow

    var interval: TimeInterval {
        switch self {
        case .fast: return 60
        case .medium: return 5 * 60
        case .slow: return 15 * 60
        }
    }

    var label: String {
        switch self {
        case .fast: return "1m"
        case .medium: return "5m"
        case .slow: return "15m"
        }
    }
}

enum FlightRankingMode: String, Codable, Hashable, Sendable {
    case aiAssisted = "ai_assisted"
    case deterministicFallback = "deterministic_fallback"

    var label: String {
        switch self {
        case .aiAssisted: return "AI Assisted"
        case .deterministicFallback: return "Deterministic"
        }
    }
}

enum FlightRiskCategory: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case disruption
    case weather
    case security
    case civil
    case health
    case migration
    case trade
    case aviation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .disruption: return "Disruption"
        case .weather: return "Weather"
        case .security: return "Security"
        case .civil: return "Civil"
        case .health: return "Health"
        case .migration: return "Migration"
        case .trade: return "Trade"
        case .aviation: return "Aviation"
        }
    }

    var tintColor: Color {
        switch self {
        case .disruption: return .orange
        case .weather: return .cyan
        case .security: return .red
        case .civil: return .yellow
        case .health: return .green
        case .migration: return .mint
        case .trade: return .blue
        case .aviation: return .purple
        }
    }
}

enum TravelRiskLevel: String, Codable, Hashable, Sendable {
    case low
    case guarded
    case elevated
    case high
    case severe

    var title: String {
        switch self {
        case .low: return "Low"
        case .guarded: return "Guarded"
        case .elevated: return "Elevated"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }

    var tintColor: Color {
        switch self {
        case .low: return .green
        case .guarded: return .mint
        case .elevated: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}

enum TravelAdvisoryLevel: Int, Codable, Hashable, Sendable {
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4

    var title: String {
        switch self {
        case .level1: return "Level 1"
        case .level2: return "Level 2"
        case .level3: return "Level 3"
        case .level4: return "Level 4"
        }
    }

    var summary: String {
        switch self {
        case .level1: return "Exercise normal precautions"
        case .level2: return "Exercise increased caution"
        case .level3: return "Reconsider travel"
        case .level4: return "Do not travel"
        }
    }

    var shortLabel: String {
        "L\(rawValue)"
    }

    var tintColor: Color {
        switch self {
        case .level1: return .green
        case .level2: return .mint
        case .level3: return .orange
        case .level4: return .red
        }
    }

    var riskBoost: Int {
        switch self {
        case .level1: return 0
        case .level2: return 7
        case .level3: return 24
        case .level4: return 40
        }
    }

    var isSaferEligible: Bool {
        self == .level1 || self == .level2
    }
}

enum TravelRiskSourceTransport: String, Codable, Hashable, Sendable {
    case rss
    case json
}

enum TravelRiskParserStrategy: String, Codable, Hashable, Sendable {
    case googleNewsSearch
    case genericRSS
    case openMeteoForecast
}

struct FlightScoutSettings: Codable, Hashable, Sendable {
    var openAIKeyServiceName: String
    var modelID: String
    var autoRefreshEnabled: Bool
    var densityMode: FlightSourceDensityMode
    var priceProviderMode: FlightPriceProviderMode
    var departureDate: Date
    var returnDate: Date
    var cabinClass: FlightCabinClass
    var adults: Int
    var trackedDestinationQueries: [String]
    var preferredCurrency: String

    init(
        openAIKeyServiceName: String = "OPENAI_API_KEY",
        modelID: String = "gpt-4.1-mini",
        autoRefreshEnabled: Bool = true,
        densityMode: FlightSourceDensityMode = .full,
        priceProviderMode: FlightPriceProviderMode = .auto,
        departureDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
        returnDate: Date = Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
        cabinClass: FlightCabinClass = .economy,
        adults: Int = 1,
        trackedDestinationQueries: [String] = [],
        preferredCurrency: String = "USD"
    ) {
        self.openAIKeyServiceName = openAIKeyServiceName
        self.modelID = modelID
        self.autoRefreshEnabled = autoRefreshEnabled
        self.densityMode = densityMode
        self.priceProviderMode = priceProviderMode
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.cabinClass = cabinClass
        self.adults = adults
        self.trackedDestinationQueries = trackedDestinationQueries
        self.preferredCurrency = preferredCurrency
    }
}

struct FlightSearchQuery: Hashable, Sendable {
    let origin: FlightPlace
    let destination: FlightPlace
    let departureDate: Date
    let returnDate: Date
    let cabinClass: FlightCabinClass
    let adults: Int
    let currencyCode: String
}

struct FlightQuote: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let providerName: String
    let title: String
    let totalPrice: Double?
    let currencyCode: String?
    let stopsText: String
    let durationText: String
    let summary: String
    let sourceURL: URL
    let bookingURL: URL
    let fetchedAt: Date
    let confidenceScore: Int

    var priceDisplay: String {
        guard let totalPrice else { return "Live search" }
        return FlightScoutFormatting.currencyString(amount: totalPrice, currencyCode: currencyCode ?? "USD")
    }
}

struct TravelWeatherSummary: Codable, Hashable, Sendable {
    let summary: String
    let maxTemperatureC: Double?
    let minTemperatureC: Double?
    let maxWindKph: Double?
    let precipitationChance: Int?
    let weatherCode: Int?
}

struct TravelRiskHeadline: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let sourceName: String
    let category: FlightRiskCategory
    let title: String
    let summary: String
    let articleURL: URL
    let publishedAt: Date?
    let weight: Int
}

struct TravelRiskBreakdown: Codable, Hashable, Sendable {
    var disruption: Int
    var weather: Int
    var security: Int
    var civil: Int
    var health: Int
    var migration: Int
    var trade: Int
    var aviation: Int

    static let zero = TravelRiskBreakdown(
        disruption: 0,
        weather: 0,
        security: 0,
        civil: 0,
        health: 0,
        migration: 0,
        trade: 0,
        aviation: 0
    )

    func score(for category: FlightRiskCategory) -> Int {
        switch category {
        case .disruption: return disruption
        case .weather: return weather
        case .security: return security
        case .civil: return civil
        case .health: return health
        case .migration: return migration
        case .trade: return trade
        case .aviation: return aviation
        }
    }
}

struct OfficialTravelAdvisory: Codable, Hashable, Sendable {
    let authorityName: String
    let level: TravelAdvisoryLevel
    let summary: String
    let reasons: [String]
    let sourceURL: URL
    let lastUpdated: Date?

    var compactLabel: String {
        "\(authorityName) \(level.shortLabel)"
    }
}

struct TravelRiskSnapshot: Codable, Hashable, Sendable {
    let score: Int
    let level: TravelRiskLevel
    let summary: String
    let breakdown: TravelRiskBreakdown
    let officialAdvisory: OfficialTravelAdvisory?
    let weatherSummary: TravelWeatherSummary?
    let headlines: [TravelRiskHeadline]
    let rankingMode: FlightRankingMode
    let lastUpdated: Date
}

struct FlightPatternSignal: Codable, Hashable, Sendable {
    let label: String
    let summary: String
}

struct FlightRouteOpportunity: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let origin: FlightPlace
    let destination: FlightPlace
    let queryText: String
    let quotes: [FlightQuote]
    let bestQuote: FlightQuote?
    let patternSignals: [FlightPatternSignal]
    let travelRisk: TravelRiskSnapshot
    let rankingScore: Int
    let rankingMode: FlightRankingMode
    let firstSeenAt: Date?
    let fetchedAt: Date
    let isNew: Bool

    var bestPriceDisplay: String {
        bestQuote?.priceDisplay ?? "Open live fares"
    }

    var bookingURL: URL {
        bestQuote?.bookingURL
            ?? FlightScoutFormatting.googleFlightsURL(
                origin: origin.iataCode,
                destination: destination.iataCode,
                departureDate: fetchedAt,
                returnDate: fetchedAt
            )
    }
}

struct SavedFlightOpportunity: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let destinationName: String
    let originName: String
    let priceDisplay: String
    let providerName: String
    let bookingURL: URL
    let riskLevel: TravelRiskLevel
    let summary: String
    let savedAt: Date

    init(opportunity: FlightRouteOpportunity, savedAt: Date = Date()) {
        self.id = opportunity.id
        self.destinationName = opportunity.destination.title
        self.originName = opportunity.origin.title
        self.priceDisplay = opportunity.bestPriceDisplay
        self.providerName = opportunity.bestQuote?.providerName ?? "Live fares"
        self.bookingURL = opportunity.bookingURL
        self.riskLevel = opportunity.travelRisk.level
        self.summary = opportunity.travelRisk.summary
        self.savedAt = savedAt
    }
}

enum FlightExportArtifactKind: String, Codable, Hashable, Sendable {
    case markdown
    case csv
    case json
}

struct FlightExportArtifact: Codable, Hashable, Identifiable, Sendable {
    let kind: FlightExportArtifactKind
    let fileURL: URL

    var id: String { fileURL.path }
}

struct TravelRiskSourceDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let category: FlightRiskCategory
    let providerName: String
    let displayName: String
    let transport: TravelRiskSourceTransport
    let refreshTier: FlightRefreshTier
    let parserStrategy: TravelRiskParserStrategy
    let baseWeight: Int
    let queryTemplate: String?
    let urlTemplate: String?
    let maxItems: Int

    func resolvedURL(origin: FlightPlace, destination: FlightPlace, departureDate: Date, returnDate: Date) -> URL? {
        switch parserStrategy {
        case .googleNewsSearch:
            guard let queryTemplate else { return nil }
            let query = FlightScoutFormatting.replacingRouteTokens(
                in: queryTemplate,
                origin: origin,
                destination: destination,
                departureDate: departureDate,
                returnDate: returnDate
            )
            return FlightScoutFormatting.googleNewsSearchURL(query: query, countryCode: destination.countryCode)
        case .genericRSS, .openMeteoForecast:
            guard let urlTemplate else { return nil }
            let value = FlightScoutFormatting.replacingRouteTokens(
                in: urlTemplate,
                origin: origin,
                destination: destination,
                departureDate: departureDate,
                returnDate: returnDate
            )
            return URL(string: value)
        }
    }
}

struct TravelRiskSourceHealth: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let category: FlightRiskCategory
    let refreshTier: FlightRefreshTier
    let lastFetchedAt: Date?
    let itemCount: Int
    let failureCount: Int
}

struct TravelRiskSourceCacheEntry: Codable, Hashable, Sendable {
    let sourceID: String
    let fingerprint: String
    let lastFetchedAt: Date
    let headlines: [TravelRiskHeadline]
    let failureCount: Int
}

struct TravelAnalysisSnapshot: Codable, Hashable, Sendable {
    let region: VPNRegion
    let origin: FlightPlace
    let routes: [FlightRouteOpportunity]
    let riskSourceHealth: [TravelRiskSourceHealth]
    let rankingMode: FlightRankingMode
    let lastUpdated: Date
    let newOpportunityCount: Int
    let statusMessage: String?
}

enum FlightSearchSignalKind: String, Codable, Hashable, Sendable {
    case exact
    case publicSignal
    case dealFeed
}

struct RawFlightSignal: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let routeID: String
    let providerName: String
    let title: String
    let price: Double?
    let currencyCode: String?
    let stopsText: String
    let durationText: String
    let summary: String
    let sourceURL: URL
    let bookingURL: URL
    let fetchedAt: Date
    let scoreHint: Int
    let kind: FlightSearchSignalKind
}

enum FlightPriceSearchMode: String, Codable, Hashable, Sendable {
    case exactAPI
    case publicSignal
}

struct FlightSearchResult: Sendable {
    let routeID: String
    let quotes: [FlightQuote]
    let mode: FlightPriceSearchMode
    let statusMessage: String?
}

enum FlightRiskSignalKind: String, Codable, Hashable, Sendable {
    case headline
    case weather
}

struct FlightScoutFormatting {
    static func shortTimestamp(from date: Date?) -> String {
        guard let date else { return "Not yet" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static func safeFilename(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    static func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    static func currencyString(amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSNumber) ?? "\(currencyCode) \(Int(amount.rounded()))"
    }

    static func googleNewsSearchURL(query: String, countryCode: String) -> URL? {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let code = countryCode.lowercased()
        return URL(string: "https://news.google.com/rss/search?q=\(encodedQuery)&hl=en-\(countryCode.uppercased())&gl=\(countryCode.uppercased())&ceid=\(code):en")
    }

    static func googleFlightsURL(origin: String, destination: String, departureDate: Date, returnDate: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let departure = formatter.string(from: departureDate)
        let returning = formatter.string(from: returnDate)
        let query = "https://www.google.com/travel/flights?hl=en#flt=\(origin).\(destination).\(departure)*\(destination).\(origin).\(returning)"
        return URL(string: query) ?? URL(string: "https://www.google.com/travel/flights")!
    }

    static func kayakURL(origin: String, destination: String, departureDate: Date, returnDate: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return URL(string: "https://www.kayak.com/flights/\(origin)-\(destination)/\(formatter.string(from: departureDate))/\(formatter.string(from: returnDate))")!
    }

    static func skyscannerURL(origin: String, destination: String, departureDate: Date, returnDate: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        return URL(string: "https://www.skyscanner.com/transport/flights/\(origin.lowercased())/\(destination.lowercased())/\(formatter.string(from: departureDate))/\(formatter.string(from: returnDate))/")!
    }

    static func replacingRouteTokens(
        in template: String,
        origin: FlightPlace,
        destination: FlightPlace,
        departureDate: Date,
        returnDate: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return template
            .replacingOccurrences(of: "{originCity}", with: origin.city)
            .replacingOccurrences(of: "{originCountry}", with: origin.countryName)
            .replacingOccurrences(of: "{originCode}", with: origin.iataCode)
            .replacingOccurrences(of: "{destinationCity}", with: destination.city)
            .replacingOccurrences(of: "{destinationCountry}", with: destination.countryName)
            .replacingOccurrences(of: "{destinationCode}", with: destination.iataCode)
            .replacingOccurrences(of: "{departureDate}", with: formatter.string(from: departureDate))
            .replacingOccurrences(of: "{returnDate}", with: formatter.string(from: returnDate))
    }

    static func deepRiskLabel(for score: Int) -> TravelRiskLevel {
        switch score {
        case ..<21: return .low
        case ..<41: return .guarded
        case ..<61: return .elevated
        case ..<81: return .high
        default: return .severe
        }
    }
}
