import Foundation

enum FlightScoutSourceCatalog {
    static let allSources: [TravelRiskSourceDefinition] = buildSources()

    static func sources(for densityMode: FlightSourceDensityMode) -> [TravelRiskSourceDefinition] {
        switch densityMode {
        case .essential:
            return allSources
                .sorted(by: sortHighWeightFirst)
                .prefix(18)
                .map { $0 }
        case .full:
            return allSources
                .sorted(by: sortHighWeightFirst)
                .prefix(32)
                .map { $0 }
        }
    }

    static func sortHighWeightFirst(lhs: TravelRiskSourceDefinition, rhs: TravelRiskSourceDefinition) -> Bool {
        if lhs.baseWeight == rhs.baseWeight {
            return lhs.id < rhs.id
        }
        return lhs.baseWeight > rhs.baseWeight
    }

    private struct Seed {
        let prefix: String
        let provider: String
        let category: FlightRiskCategory
        let query: String
        let tier: FlightRefreshTier
        let weight: Int
    }

    private static func buildSources() -> [TravelRiskSourceDefinition] {
        var definitions: [TravelRiskSourceDefinition] = [
            TravelRiskSourceDefinition(
                id: "open-meteo-forecast",
                category: .weather,
                providerName: "Open-Meteo",
                displayName: "Destination Forecast",
                transport: .json,
                refreshTier: .fast,
                parserStrategy: .openMeteoForecast,
                baseWeight: 98,
                queryTemplate: nil,
                urlTemplate: "https://api.open-meteo.com/v1/forecast",
                maxItems: 1
            )
        ]

        definitions += buildSeeds().enumerated().map { index, seed in
            TravelRiskSourceDefinition(
                id: "\(seed.prefix)-\(index + 1)",
                category: seed.category,
                providerName: seed.provider,
                displayName: seed.query
                    .replacingOccurrences(of: "{originCity}", with: "")
                    .replacingOccurrences(of: "{destinationCity}", with: "")
                    .replacingOccurrences(of: "{destinationCountry}", with: "")
                    .replacingOccurrences(of: "{originCountry}", with: "")
                    .replacingOccurrences(of: "  ", with: " ")
                    .trimmingCharacters(in: .whitespaces),
                transport: .rss,
                refreshTier: seed.tier,
                parserStrategy: .googleNewsSearch,
                baseWeight: seed.weight,
                queryTemplate: seed.query,
                urlTemplate: nil,
                maxItems: 2
            )
        }

        return definitions
    }

    private static func buildSeeds() -> [Seed] {
        let disruption = [
            "\"{destinationCity}\" airport delays",
            "\"{destinationCity}\" flight cancellations",
            "\"{destinationCity}\" airport strike",
            "\"{destinationCountry}\" air traffic control disruption",
            "\"{originCity}\" to \"{destinationCity}\" route delays",
            "\"{destinationCountry}\" airline strike",
            "\"{destinationCity}\" baggage disruption",
            "\"{destinationCountry}\" airport shutdown",
            "\"{destinationCountry}\" visa delays",
            "\"{destinationCountry}\" border queue airport",
            "\"{destinationCity}\" airport congestion",
            "\"{destinationCity}\" airline disruption",
            "\"{destinationCountry}\" transport strike",
            "\"{destinationCountry}\" fuel protest airport"
        ]

        let weather = [
            "\"{destinationCity}\" severe weather airport",
            "\"{destinationCity}\" thunderstorm travel warning",
            "\"{destinationCity}\" flood warning airport",
            "\"{destinationCountry}\" cyclone travel warning",
            "\"{destinationCountry}\" heavy rain airport disruption",
            "\"{destinationCity}\" snow airport disruption",
            "\"{destinationCity}\" heatwave travel warning",
            "\"{destinationCountry}\" monsoon airport delays",
            "\"{destinationCountry}\" turbulence warning flights",
            "\"{destinationCity}\" wildfire smoke airport",
            "\"{destinationCountry}\" typhoon travel update",
            "\"{destinationCity}\" wind warning airport",
            "\"{destinationCountry}\" fog airport delays",
            "\"{destinationCountry}\" landslide travel warning"
        ]

        let security = [
            "\"{destinationCountry}\" terrorism alert travel",
            "\"{destinationCity}\" airport security incident",
            "\"{destinationCountry}\" travel security warning",
            "\"{destinationCountry}\" embassy travel advisory",
            "\"{destinationCity}\" airport evacuation",
            "\"{destinationCountry}\" terror threat airport",
            "\"{destinationCountry}\" cyberattack airport",
            "\"{destinationCountry}\" violent incident tourist",
            "\"{destinationCountry}\" airline security alert",
            "\"{destinationCountry}\" foreign office travel advice",
            "\"{destinationCity}\" airport police incident",
            "\"{destinationCountry}\" suspicious package airport",
            "\"{destinationCountry}\" border security crackdown",
            "\"{destinationCountry}\" travel alert airport"
        ]

        let civil = [
            "\"{destinationCountry}\" protests travel",
            "\"{destinationCity}\" protest airport road",
            "\"{destinationCountry}\" civil unrest tourism",
            "\"{destinationCountry}\" elections travel warning",
            "\"{destinationCountry}\" riot travel update",
            "\"{destinationCity}\" demonstrations airport",
            "\"{destinationCountry}\" curfew travel alert",
            "\"{destinationCountry}\" emergency law travel",
            "\"{destinationCountry}\" political unrest flights",
            "\"{destinationCountry}\" city shutdown travel",
            "\"{destinationCountry}\" police protest airport",
            "\"{destinationCountry}\" border protest crossings",
            "\"{destinationCountry}\" tourist scams crackdown",
            "\"{destinationCountry}\" crowd control airport"
        ]

        let health = [
            "\"{destinationCountry}\" disease outbreak travel",
            "\"{destinationCountry}\" public health travel advisory",
            "\"{destinationCity}\" dengue warning travelers",
            "\"{destinationCountry}\" influenza travel alert",
            "\"{destinationCountry}\" vaccination requirement travelers",
            "\"{destinationCountry}\" hospital strain travel",
            "\"{destinationCountry}\" food poisoning tourist warning",
            "\"{destinationCountry}\" water contamination travel",
            "\"{destinationCountry}\" air quality tourist warning",
            "\"{destinationCountry}\" respiratory illness airport",
            "\"{destinationCountry}\" heat illness travelers",
            "\"{destinationCountry}\" measles travel alert",
            "\"{destinationCountry}\" travel clinic warning",
            "\"{destinationCountry}\" health ministry tourist notice"
        ]

        let migration = [
            "\"{destinationCountry}\" migration pressure border",
            "\"{destinationCountry}\" refugee crossings airport security",
            "\"{destinationCountry}\" visa restrictions travelers",
            "\"{destinationCountry}\" deportation policy tourists",
            "\"{destinationCountry}\" entry restrictions travelers",
            "\"{destinationCountry}\" passport control queues",
            "\"{destinationCountry}\" immigration backlog airport",
            "\"{destinationCountry}\" asylum surge border",
            "\"{destinationCountry}\" customs crackdown arrivals",
            "\"{destinationCountry}\" overstays enforcement tourists",
            "\"{destinationCountry}\" transit restrictions airport",
            "\"{destinationCountry}\" arrival form travelers",
            "\"{destinationCountry}\" biometric border checks",
            "\"{destinationCountry}\" migration tensions travelers"
        ]

        let trade = [
            "\"{destinationCountry}\" trade war travel",
            "\"{destinationCountry}\" sanctions aviation",
            "\"{destinationCountry}\" fuel prices airline costs",
            "\"{destinationCountry}\" currency shock tourism",
            "\"{destinationCountry}\" airline tax increase",
            "\"{destinationCountry}\" air fare increase travel",
            "\"{destinationCountry}\" recession tourism demand",
            "\"{destinationCountry}\" port disruption supply travel",
            "\"{destinationCountry}\" import controls travel goods",
            "\"{destinationCountry}\" airline bankruptcy risk",
            "\"{destinationCountry}\" travel industry layoffs",
            "\"{destinationCountry}\" hotel tax rise tourists",
            "\"{destinationCountry}\" geopolitical tensions travel",
            "\"{destinationCountry}\" customs tariffs tourism"
        ]

        let aviation = [
            "\"{destinationCountry}\" airspace closure",
            "\"{destinationCountry}\" notam flight disruption",
            "\"{destinationCountry}\" runway incident",
            "\"{destinationCountry}\" aviation authority warning",
            "\"{originCity}\" to \"{destinationCity}\" route conflict",
            "\"{destinationCountry}\" drone incident airport",
            "\"{destinationCountry}\" airline safety audit",
            "\"{destinationCountry}\" airport ground stop",
            "\"{destinationCountry}\" military exercise airspace",
            "\"{destinationCountry}\" emergency landing airport",
            "\"{destinationCountry}\" navigation outage airport",
            "\"{destinationCountry}\" pilot strike route",
            "\"{destinationCountry}\" aircraft inspection delays",
            "\"{destinationCountry}\" airport slot restrictions"
        ]

        var seeds: [Seed] = []
        seeds += makeSeeds(prefix: "disruption", provider: "Disruption Watch", category: .disruption, queries: disruption, tier: .fast, weight: 89)
        seeds += makeSeeds(prefix: "weather", provider: "Weather Watch", category: .weather, queries: weather, tier: .fast, weight: 91)
        seeds += makeSeeds(prefix: "security", provider: "Security Watch", category: .security, queries: security, tier: .medium, weight: 90)
        seeds += makeSeeds(prefix: "civil", provider: "Civil Watch", category: .civil, queries: civil, tier: .medium, weight: 85)
        seeds += makeSeeds(prefix: "health", provider: "Health Watch", category: .health, queries: health, tier: .slow, weight: 82)
        seeds += makeSeeds(prefix: "migration", provider: "Mobility Watch", category: .migration, queries: migration, tier: .slow, weight: 78)
        seeds += makeSeeds(prefix: "trade", provider: "Trade Watch", category: .trade, queries: trade, tier: .medium, weight: 79)
        seeds += makeSeeds(prefix: "aviation", provider: "Aviation Watch", category: .aviation, queries: aviation, tier: .fast, weight: 92)
        return seeds
    }

    private static func makeSeeds(
        prefix: String,
        provider: String,
        category: FlightRiskCategory,
        queries: [String],
        tier: FlightRefreshTier,
        weight: Int
    ) -> [Seed] {
        queries.enumerated().map { index, query in
            Seed(
                prefix: prefix,
                provider: provider,
                category: category,
                query: query,
                tier: tier,
                weight: max(60, weight - (index / 4))
            )
        }
    }
}
