import Foundation

struct FlightWeatherService: Sendable {
    func fetch(destination: FlightPlace, departureDate: Date, returnDate: Date) async -> TravelWeatherSummary? {
        guard let latitude = destination.latitude, let longitude = destination.longitude else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "daily", value: "weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max"),
            .init(name: "timezone", value: "auto"),
            .init(name: "start_date", value: formatter.string(from: departureDate)),
            .init(name: "end_date", value: formatter.string(from: returnDate))
        ]

        do {
            var request = URLRequest(url: components.url!)
            request.timeoutInterval = 20
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }

            guard
                let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let daily = root["daily"] as? [String: Any]
            else {
                return nil
            }

            let maxTemps = daily["temperature_2m_max"] as? [Double]
            let minTemps = daily["temperature_2m_min"] as? [Double]
            let precip = (daily["precipitation_probability_max"] as? [Int]) ?? ((daily["precipitation_probability_max"] as? [Double])?.map { Int($0.rounded()) })
            let wind = daily["wind_speed_10m_max"] as? [Double]
            let codes = (daily["weathercode"] as? [Int]) ?? ((daily["weathercode"] as? [Double])?.map { Int($0.rounded()) })

            let maxTemp = maxTemps?.max()
            let minTemp = minTemps?.min()
            let precipMax = precip?.max()
            let windMax = wind?.max()
            let code = codes?.first

            return TravelWeatherSummary(
                summary: summary(for: code, precipChance: precipMax, wind: windMax),
                maxTemperatureC: maxTemp,
                minTemperatureC: minTemp,
                maxWindKph: windMax,
                precipitationChance: precipMax,
                weatherCode: code
            )
        } catch {
            return nil
        }
    }

    private func summary(for code: Int?, precipChance: Int?, wind: Double?) -> String {
        var parts: [String] = []

        if let precipChance {
            if precipChance >= 70 {
                parts.append("heavy rain risk")
            } else if precipChance >= 40 {
                parts.append("possible showers")
            }
        }

        if let wind, wind >= 35 {
            parts.append("strong winds")
        }

        switch code {
        case 95, 96, 99:
            parts.append("storm pattern")
        case 71, 73, 75, 77:
            parts.append("snow disruption")
        case 45, 48:
            parts.append("fog risk")
        case 61, 63, 65, 80, 81, 82:
            parts.append("rainy conditions")
        default:
            break
        }

        return parts.isEmpty ? "No major weather signal" : parts.joined(separator: " • ")
    }
}
