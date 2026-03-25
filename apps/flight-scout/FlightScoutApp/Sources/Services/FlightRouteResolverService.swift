import Foundation

struct FlightRouteResolverService: Sendable {
    private let places: [FlightPlace] = Self.directory

    func resolveOrigin(for region: VPNRegion) -> FlightPlace {
        if let byCity = match(query: region.city) {
            return byCity
        }
        if let byCountry = places.first(where: { $0.countryCode == region.countryCode }) {
            return byCountry
        }
        return Self.directory.first(where: { $0.iataCode == "SIN" }) ?? Self.directory[0]
    }

    func resolveDestination(query: String) -> FlightPlace? {
        match(query: query)
    }

    func defaultTrackedQueries(for region: VPNRegion) -> [String] {
        switch region.countryCode {
        case "SG":
            return ["New York", "London", "Adelaide", "Mumbai", "Brazil"]
        case "US":
            return ["London", "Tokyo", "Singapore", "Paris", "Dubai"]
        case "GB":
            return ["Singapore", "New York", "Mumbai", "Barcelona", "Dubai"]
        default:
            return ["London", "New York", "Singapore", "Dubai", "Tokyo"]
        }
    }

    private func match(query: String) -> FlightPlace? {
        let normalized = normalize(query)
        guard !normalized.isEmpty else { return nil }

        if let exact = places.first(where: { place in
            place.aliases.map(normalize).contains(normalized)
                || normalize(place.city) == normalized
                || normalize(place.countryName) == normalized
                || normalize(place.iataCode) == normalized
        }) {
            return exact
        }

        return places
            .map { place in
                (place, score(for: normalized, place: place))
            }
            .filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.city < rhs.0.city
                }
                return lhs.1 > rhs.1
            }
            .first?
            .0
    }

    private func score(for normalizedQuery: String, place: FlightPlace) -> Int {
        let candidates = ([place.city, place.countryName, place.iataCode, place.airportName] + place.aliases).map(normalize)
        var score = 0
        for candidate in candidates {
            if candidate == normalizedQuery {
                score += 100
            } else if candidate.contains(normalizedQuery) || normalizedQuery.contains(candidate) {
                score += 45
            } else if candidate.split(separator: " ").contains(where: { normalizedQuery.contains($0) }) {
                score += 20
            }
        }
        return score
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension FlightRouteResolverService {
    static let directory: [FlightPlace] = [
        place("SIN", "Singapore", "SG", "Singapore", "Singapore Changi Airport", 1.3644, 103.9915, aliases: ["singapore", "sg"]),
        place("JFK", "New York", "US", "United States", "John F. Kennedy International Airport", 40.6413, -73.7781, aliases: ["new york", "nyc", "new york city", "jfk", "usa"]),
        place("EWR", "Newark", "US", "United States", "Newark Liberty International Airport", 40.6895, -74.1745, aliases: ["newark", "ewr"]),
        place("LHR", "London", "GB", "United Kingdom", "Heathrow Airport", 51.47, -0.4543, aliases: ["london", "uk", "united kingdom", "england"]),
        place("LGW", "London", "GB", "United Kingdom", "Gatwick Airport", 51.1537, -0.1821, aliases: ["gatwick"]),
        place("ADL", "Adelaide", "AU", "Australia", "Adelaide Airport", -34.945, 138.5306, aliases: ["adelaide", "south australia"]),
        place("BOM", "Mumbai", "IN", "India", "Chhatrapati Shivaji Maharaj International Airport", 19.0896, 72.8656, aliases: ["mumbai", "bombay", "india"]),
        place("DEL", "Delhi", "IN", "India", "Indira Gandhi International Airport", 28.5562, 77.1, aliases: ["delhi", "new delhi"]),
        place("GRU", "Sao Paulo", "BR", "Brazil", "São Paulo/Guarulhos International Airport", -23.4356, -46.4731, aliases: ["brazil", "brasil", "sao paulo", "são paulo"]),
        place("GIG", "Rio de Janeiro", "BR", "Brazil", "Rio de Janeiro/Galeão International Airport", -22.809, -43.2506, aliases: ["rio", "rio de janeiro"]),
        place("DXB", "Dubai", "AE", "United Arab Emirates", "Dubai International Airport", 25.2532, 55.3657, aliases: ["dubai", "uae"]),
        place("HND", "Tokyo", "JP", "Japan", "Haneda Airport", 35.5494, 139.7798, aliases: ["tokyo", "japan"]),
        place("NRT", "Tokyo", "JP", "Japan", "Narita International Airport", 35.772, 140.3929, aliases: ["narita"]),
        place("CDG", "Paris", "FR", "France", "Charles de Gaulle Airport", 49.0097, 2.5479, aliases: ["paris", "france"]),
        place("FRA", "Frankfurt", "DE", "Germany", "Frankfurt Airport", 50.0379, 8.5622, aliases: ["frankfurt", "germany"]),
        place("AMS", "Amsterdam", "NL", "Netherlands", "Amsterdam Airport Schiphol", 52.3105, 4.7683, aliases: ["amsterdam", "netherlands"]),
        place("MAD", "Madrid", "ES", "Spain", "Adolfo Suarez Madrid-Barajas Airport", 40.4983, -3.5676, aliases: ["madrid", "spain"]),
        place("BCN", "Barcelona", "ES", "Spain", "Barcelona-El Prat Airport", 41.2974, 2.0833, aliases: ["barcelona"]),
        place("FCO", "Rome", "IT", "Italy", "Leonardo da Vinci International Airport", 41.8003, 12.2389, aliases: ["rome", "italy"]),
        place("IST", "Istanbul", "TR", "Turkey", "Istanbul Airport", 41.2753, 28.7519, aliases: ["istanbul", "turkey"]),
        place("CAI", "Cairo", "EG", "Egypt", "Cairo International Airport", 30.1219, 31.4056, aliases: ["cairo", "egypt"]),
        place("JNB", "Johannesburg", "ZA", "South Africa", "O.R. Tambo International Airport", -26.1337, 28.242, aliases: ["johannesburg", "south africa"]),
        place("DOH", "Doha", "QA", "Qatar", "Hamad International Airport", 25.2731, 51.6081, aliases: ["doha", "qatar"]),
        place("BKK", "Bangkok", "TH", "Thailand", "Suvarnabhumi Airport", 13.69, 100.7501, aliases: ["bangkok", "thailand"]),
        place("HKG", "Hong Kong", "HK", "Hong Kong", "Hong Kong International Airport", 22.308, 113.9185, aliases: ["hong kong", "hk"]),
        place("ICN", "Seoul", "KR", "South Korea", "Incheon International Airport", 37.4602, 126.4407, aliases: ["seoul", "south korea", "korea"]),
        place("SYD", "Sydney", "AU", "Australia", "Sydney Airport", -33.9399, 151.1753, aliases: ["sydney"]),
        place("MEL", "Melbourne", "AU", "Australia", "Melbourne Airport", -37.669, 144.841, aliases: ["melbourne"]),
        place("LAX", "Los Angeles", "US", "United States", "Los Angeles International Airport", 33.9416, -118.4085, aliases: ["los angeles", "la"]),
        place("SFO", "San Francisco", "US", "United States", "San Francisco International Airport", 37.6213, -122.379, aliases: ["san francisco", "sf"]),
        place("ORD", "Chicago", "US", "United States", "O'Hare International Airport", 41.9742, -87.9073, aliases: ["chicago"]),
        place("YYZ", "Toronto", "CA", "Canada", "Toronto Pearson International Airport", 43.6777, -79.6248, aliases: ["toronto", "canada"]),
        place("YVR", "Vancouver", "CA", "Canada", "Vancouver International Airport", 49.1967, -123.1815, aliases: ["vancouver"]),
        place("AKL", "Auckland", "NZ", "New Zealand", "Auckland Airport", -37.0082, 174.785, aliases: ["auckland", "new zealand"]),
        place("MEX", "Mexico City", "MX", "Mexico", "Benito Juárez International Airport", 19.4361, -99.0719, aliases: ["mexico city", "mexico"]),
        place("LIS", "Lisbon", "PT", "Portugal", "Humberto Delgado Airport", 38.7742, -9.1342, aliases: ["lisbon", "portugal"]),
        place("ATH", "Athens", "GR", "Greece", "Athens International Airport", 37.9364, 23.9475, aliases: ["athens", "greece"]),
        place("MNL", "Manila", "PH", "Philippines", "Ninoy Aquino International Airport", 14.5086, 121.0198, aliases: ["manila", "philippines"]),
        place("KUL", "Kuala Lumpur", "MY", "Malaysia", "Kuala Lumpur International Airport", 2.7456, 101.71, aliases: ["kuala lumpur", "malaysia"]),
        place("CGK", "Jakarta", "ID", "Indonesia", "Soekarno-Hatta International Airport", -6.1256, 106.6559, aliases: ["jakarta", "indonesia"])
    ]

    static func place(
        _ code: String,
        _ city: String,
        _ countryCode: String,
        _ countryName: String,
        _ airportName: String,
        _ latitude: Double?,
        _ longitude: Double?,
        aliases: [String]
    ) -> FlightPlace {
        FlightPlace(
            id: code,
            iataCode: code,
            city: city,
            countryCode: countryCode,
            countryName: countryName,
            airportName: airportName,
            latitude: latitude,
            longitude: longitude,
            aliases: aliases
        )
    }
}
