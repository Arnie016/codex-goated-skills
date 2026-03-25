import Foundation

enum VPNRegionServiceError: LocalizedError {
    case invalidResponse
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Could not read the current VPN region."
        case .invalidPayload:
            return "The VPN region service returned an unexpected payload."
        }
    }
}

struct VPNRegionService: Sendable {
    func detectCurrentRegion() async throws -> VPNRegion {
        let url = URL(string: "https://ipinfo.io/json")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw VPNRegionServiceError.invalidResponse
        }

        return try Self.parseRegion(data: data)
    }

    static func parseRegion(data: Data) throws -> VPNRegion {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let countryCode = root["country"] as? String
        else {
            throw VPNRegionServiceError.invalidPayload
        }

        let countryName = Locale.current.localizedString(forRegionCode: countryCode.uppercased()) ?? countryCode.uppercased()
        let loc = (root["loc"] as? String)?.split(separator: ",").map(String.init) ?? []
        let latitude = loc.count == 2 ? Double(loc[0]) : nil
        let longitude = loc.count == 2 ? Double(loc[1]) : nil

        return VPNRegion(
            ipAddress: root["ip"] as? String ?? "",
            city: root["city"] as? String ?? "",
            regionName: root["region"] as? String ?? "",
            countryCode: countryCode.uppercased(),
            countryName: countryName,
            timezone: root["timezone"] as? String ?? "",
            latitude: latitude,
            longitude: longitude
        )
    }
}
