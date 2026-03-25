import Foundation
import VibeWidgetCore

actor FlightScoutRankingService {
    private let keychain = KeychainSecretStore()

    func rank(
        opportunities: [FlightRouteOpportunity],
        region: VPNRegion,
        settings: FlightScoutSettings
    ) async -> (FlightRankingMode, [FlightRouteOpportunity]) {
        let deterministic = deterministicRank(opportunities)
        guard !deterministic.isEmpty else {
            return (.deterministicFallback, [])
        }

        guard let apiKey = await resolveAPIKey(serviceName: settings.openAIKeyServiceName), !apiKey.isEmpty else {
            return (.deterministicFallback, deterministic)
        }

        do {
            let aiItems = try await aiRank(
                candidates: Array(deterministic.prefix(8)),
                region: region,
                apiKey: apiKey,
                modelID: settings.modelID
            )
            let lookup = Dictionary(uniqueKeysWithValues: deterministic.map { ($0.id, $0) })
            let merged = aiItems.compactMap { item -> FlightRouteOpportunity? in
                guard let base = lookup[item.id] else { return nil }
                let updatedSignals = item.pattern.flatMap { pattern -> [FlightPatternSignal]? in
                    let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return nil }
                    return [FlightPatternSignal(label: "AI Pattern", summary: trimmed)]
                } ?? base.patternSignals
                let summarizedRisk: String = {
                    guard let riskSummary = item.riskSummary?.trimmingCharacters(in: .whitespacesAndNewlines), !riskSummary.isEmpty else {
                        return base.travelRisk.summary
                    }
                    return riskSummary
                }()
                let updatedRisk = TravelRiskSnapshot(
                    score: base.travelRisk.score,
                    level: base.travelRisk.level,
                    summary: summarizedRisk,
                    breakdown: base.travelRisk.breakdown,
                    officialAdvisory: base.travelRisk.officialAdvisory,
                    weatherSummary: base.travelRisk.weatherSummary,
                    headlines: base.travelRisk.headlines,
                    rankingMode: .aiAssisted,
                    lastUpdated: base.travelRisk.lastUpdated
                )
                return FlightRouteOpportunity(
                    id: base.id,
                    origin: base.origin,
                    destination: base.destination,
                    queryText: base.queryText,
                    quotes: base.quotes,
                    bestQuote: base.bestQuote,
                    patternSignals: updatedSignals,
                    travelRisk: updatedRisk,
                    rankingScore: max(base.rankingScore, item.score),
                    rankingMode: .aiAssisted,
                    firstSeenAt: base.firstSeenAt,
                    fetchedAt: base.fetchedAt,
                    isNew: base.isNew
                )
            }

            if merged.isEmpty {
                return (.deterministicFallback, deterministic)
            }

            return (.aiAssisted, merged.sorted { lhs, rhs in
                if lhs.rankingScore == rhs.rankingScore {
                    return lhs.destination.city < rhs.destination.city
                }
                return lhs.rankingScore > rhs.rankingScore
            })
        } catch {
            return (.deterministicFallback, deterministic)
        }
    }

    func deterministicRank(_ opportunities: [FlightRouteOpportunity]) -> [FlightRouteOpportunity] {
        opportunities
            .map { opportunity in
                let riskPenalty = opportunity.travelRisk.score / 2
                let priceBonus: Int
                if let price = opportunity.bestQuote?.totalPrice {
                    priceBonus = max(0, 65 - Int(price / 40))
                } else {
                    priceBonus = 22
                }

                let directBonus = opportunity.bestQuote?.stopsText.localizedCaseInsensitiveContains("Direct") == true ? 12 : 0
                let newBonus = opportunity.isNew ? 8 : 0
                let providerBonus = min(opportunity.quotes.count * 3, 12)
                let score = max(18, priceBonus + directBonus + newBonus + providerBonus + (100 - riskPenalty))

                return FlightRouteOpportunity(
                    id: opportunity.id,
                    origin: opportunity.origin,
                    destination: opportunity.destination,
                    queryText: opportunity.queryText,
                    quotes: opportunity.quotes,
                    bestQuote: opportunity.bestQuote,
                    patternSignals: opportunity.patternSignals,
                    travelRisk: opportunity.travelRisk,
                    rankingScore: score,
                    rankingMode: .deterministicFallback,
                    firstSeenAt: opportunity.firstSeenAt,
                    fetchedAt: opportunity.fetchedAt,
                    isNew: opportunity.isNew
                )
            }
            .sorted { lhs, rhs in
                if lhs.rankingScore == rhs.rankingScore {
                    return lhs.destination.city < rhs.destination.city
                }
                return lhs.rankingScore > rhs.rankingScore
            }
    }

    private func resolveAPIKey(serviceName: String) async -> String? {
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }

        let trimmed = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let key = try? keychain.read(service: trimmed), !key.isEmpty else {
            return nil
        }
        return key
    }

    private func aiRank(
        candidates: [FlightRouteOpportunity],
        region: VPNRegion,
        apiKey: String,
        modelID: String
    ) async throws -> [AIRouteRankingItem] {
        let lines = candidates.map { route in
            let price = route.bestQuote?.priceDisplay ?? "Live search"
            let pattern = route.patternSignals.map(\.summary).joined(separator: " | ")
            return """
            {"id":"\(route.id)","destination":"\(route.destination.city)","price":"\(price)","risk":"\(route.travelRisk.level.title)","riskScore":\(route.travelRisk.score),"provider":"\(route.bestQuote?.providerName ?? "Live")","pattern":"\(escaped(pattern))"}
            """
        }.joined(separator: "\n")

        let system = """
        Return only minified JSON.
        Output an array with objects: id, score, pattern, riskSummary.
        Keep pattern under 10 words and riskSummary under 18 words.
        Rank for a user flying from \(region.displayTitle).
        Balance price, route quality, and safety. Do not invent prices.
        """

        let payload: [String: Any] = [
            "model": modelID,
            "input": [
                ["role": "system", "content": [["type": "input_text", "text": system]]],
                ["role": "user", "content": [["type": "input_text", "text": lines]]]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data)
        let text = extractText(from: json) ?? "[]"
        let arrayText = firstJSONArray(in: text) ?? text
        guard let jsonData = arrayText.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([AIRouteRankingItem].self, from: jsonData)) ?? []
    }

    private func extractText(from value: Any) -> String? {
        if let string = value as? String, string.contains("[") {
            return string
        }
        if let dictionary = value as? [String: Any] {
            if let outputText = dictionary["output_text"] as? String {
                return outputText
            }
            for nested in dictionary.values {
                if let match = extractText(from: nested) {
                    return match
                }
            }
        }
        if let array = value as? [Any] {
            for item in array {
                if let match = extractText(from: item) {
                    return match
                }
            }
        }
        return nil
    }

    private func firstJSONArray(in string: String) -> String? {
        guard let start = string.firstIndex(of: "["), let end = string.lastIndex(of: "]") else {
            return nil
        }
        return String(string[start...end])
    }

    private func escaped(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }
}

private struct AIRouteRankingItem: Codable {
    let id: String
    let score: Int
    let pattern: String?
    let riskSummary: String?
}
