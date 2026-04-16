import Foundation

struct ParsedCurrentNetwork {
    let name: String
    let security: String
    let channel: String
    let phyMode: String
    let signal: Int?
    let noise: Int?
    let txRate: Int?
}

struct WifiTrustScorer {
    struct ScoreAssessment {
        let score: Int
        let confidence: Int
        let trustLevel: TrustLevel
        let guidanceTitle: String
        let guidanceDetail: String
        let factors: [ScoreFactor]
        let issues: [SafetyIssue]
    }

    func assessNetwork(
        current: ParsedCurrentNetwork,
        connectionKind: String?,
        gateway: String,
        dnsServers: [String],
        captivePortal: Bool,
        nearbyNetworks: [NearbyNetwork]
    ) -> ScoreAssessment {
        let isHotspot = connectionKind?.localizedCaseInsensitiveContains("hotspot") ?? false
        let security = current.security.lowercased()
        var issues: [SafetyIssue] = []
        var factors: [ScoreFactor] = []

        let securityFactor: ScoreFactor = {
            if security.contains("none") || security.contains("open") {
                issues.append(SafetyIssue(title: "Open network", detail: "The current Wi-Fi is not encrypting traffic over the air.", level: .avoid))
                return makeFactor(title: "Security", points: 0, maxPoints: 30, detail: "Open Wi-Fi provides no link-layer protection, so nearby interception risk is high.")
            }

            if security.contains("wep") {
                issues.append(SafetyIssue(title: "Weak Wi-Fi security", detail: "WEP is obsolete and should be treated as unsafe.", level: .avoid))
                return makeFactor(title: "Security", points: 4, maxPoints: 30, detail: "WEP is outdated and practically unsafe.")
            }

            if security.contains("wpa3") {
                return makeFactor(title: "Security", points: 30, maxPoints: 30, detail: "WPA3 is current-generation Wi-Fi protection and is a strong signal for the radio link.")
            }

            if security.contains("wpa2") && security.contains("enterprise") {
                return makeFactor(title: "Security", points: 28, maxPoints: 30, detail: "WPA2 Enterprise is still a strong managed-network setup.")
            }

            if security.contains("wpa2") {
                if isHotspot {
                    issues.append(SafetyIssue(title: connectionKind ?? "Phone hotspot", detail: "Your own hotspot is typically more trusted than random public Wi-Fi.", level: .safe))
                    return makeFactor(title: "Security", points: 27, maxPoints: 30, detail: "WPA2 on your own phone hotspot is usually fine, even if it is older than WPA3.")
                }

                issues.append(SafetyIssue(title: "Older security standard", detail: "The network is using WPA2 instead of WPA3. Usable, but older.", level: .caution))
                return makeFactor(title: "Security", points: 22, maxPoints: 30, detail: "WPA2 is still common and usable, but it is older than WPA3.")
            }

            if security.contains("wpa") {
                issues.append(SafetyIssue(title: "Legacy WPA security", detail: "The network is relying on an older WPA mode.", level: .caution))
                return makeFactor(title: "Security", points: 16, maxPoints: 30, detail: "Legacy WPA is weaker than WPA2 or WPA3.")
            }

            issues.append(SafetyIssue(title: "Unknown Wi-Fi security", detail: "The current network's encryption could not be identified confidently.", level: .caution))
            return makeFactor(title: "Security", points: 18, maxPoints: 30, detail: "The Wi-Fi security mode could not be identified cleanly, so the grade is conservative.")
        }()
        factors.append(securityFactor)

        let ownershipFactor: ScoreFactor = {
            if isHotspot {
                return makeFactor(title: "Ownership", points: 19, maxPoints: 20, detail: "This looks like your own phone hotspot, which is usually more trustworthy than venue or shared Wi-Fi.")
            }

            if captivePortal {
                issues.append(SafetyIssue(title: "Captive portal detected", detail: "This network appears to intercept traffic until browser sign-in completes.", level: .caution))
                return makeFactor(title: "Ownership", points: 8, maxPoints: 20, detail: "Captive portal behavior usually means a hotel, airport, cafe, or other shared network you do not control.")
            }

            if !gateway.isEmpty, isPrivateAddress(gateway) {
                return makeFactor(title: "Ownership", points: 16, maxPoints: 20, detail: "A private LAN-style gateway is more consistent with home, office, or personally controlled Wi-Fi.")
            }

            if gateway.isEmpty {
                return makeFactor(title: "Ownership", points: 10, maxPoints: 20, detail: "The app could not confirm the gateway, so ownership confidence is lower.")
            }

            return makeFactor(title: "Ownership", points: 11, maxPoints: 20, detail: "There is no strong personal-control signal here, so the network is treated as shared or unknown.")
        }()
        factors.append(ownershipFactor)

        let routingFactor: ScoreFactor = {
            var points = 20
            var notes: [String] = []

            if gateway.isEmpty {
                points -= 6
                notes.append("gateway was not confirmed")
            } else if !isPrivateAddress(gateway) && !isHotspot {
                points -= 12
                notes.append("gateway is outside the usual private LAN ranges")
                issues.append(SafetyIssue(title: "Gateway looks unusual", detail: "The default gateway is not in a normal private LAN range.", level: .avoid))
            } else {
                notes.append("gateway looks normal")
            }

            if dnsServers.isEmpty {
                points -= 6
                notes.append("no DNS servers were found")
                issues.append(SafetyIssue(title: "No DNS servers found", detail: "DNS settings could not be confirmed.", level: .caution))
            } else if dnsServers.contains(where: { !$0.isEmpty && !isPlausibleIPAddress($0) }) {
                points -= 6
                notes.append("one or more DNS values looked malformed")
                issues.append(SafetyIssue(title: "DNS parsing issue", detail: "One or more DNS entries looked malformed.", level: .caution))
            } else {
                notes.append("DNS values look normal")
            }

            if captivePortal {
                points -= 5
                notes.append("captive portal behavior was detected")
            }

            return makeFactor(title: "Routing", points: points, maxPoints: 20, detail: notes.joined(separator: "; ").capitalized + ".")
        }()
        factors.append(routingFactor)

        let signalFactor: ScoreFactor = {
            var points = 8
            var notes = "Signal strength could not be measured cleanly."

            if let signal = current.signal {
                switch signal {
                case -55...0:
                    points = 15
                    notes = "Strong signal. You are likely close to the access point."
                case -67 ..< -55:
                    points = 13
                    notes = "Good signal. This should behave normally for everyday use."
                case -75 ..< -67:
                    points = 10
                    notes = "Fair signal. Expect occasional instability if the area is busy."
                default:
                    points = 6
                    notes = "Weak signal. Reliability and responsiveness can get worse at this range."
                    issues.append(SafetyIssue(title: "Weak signal", detail: "Weak Wi-Fi often means more retries and less stability.", level: .caution))
                }
            }

            if let signal = current.signal, let noise = current.noise {
                let snr = signal - noise
                if snr < 20 {
                    points = max(0, points - 2)
                    notes += " Signal-to-noise margin is modest."
                }
            }

            return makeFactor(title: "Signal", points: points, maxPoints: 15, detail: notes)
        }()
        factors.append(signalFactor)

        let environmentFactor: ScoreFactor = {
            let insecureNearby = nearbyNetworks.filter {
                $0.security.localizedCaseInsensitiveContains("none") || $0.security.localizedCaseInsensitiveContains("wep")
            }.count

            if isHotspot {
                return makeFactor(
                    title: "Environment",
                    points: insecureNearby >= 4 ? 12 : 14,
                    maxPoints: 15,
                    detail: insecureNearby == 0
                        ? "Nearby Wi-Fi looks quiet, and because you are on your own hotspot the neighborhood matters less."
                        : "There are \(insecureNearby) weak nearby networks, but they matter less because you are using your own hotspot."
                )
            }

            var points = 15
            if insecureNearby >= 4 {
                points = 6
                issues.append(SafetyIssue(title: "Many insecure hotspots nearby", detail: "This area has several open or weakly secured Wi-Fi networks.", level: .caution))
            } else if insecureNearby == 3 {
                points = 8
                issues.append(SafetyIssue(title: "Many insecure hotspots nearby", detail: "This area has multiple weak nearby networks.", level: .caution))
            } else if insecureNearby == 2 {
                points = 11
            } else if insecureNearby == 1 {
                points = 13
            }

            if current.channel.contains("(2GHz") || current.channel.contains("2GHz") {
                points = max(0, points - 2)
                issues.append(SafetyIssue(title: "2.4 GHz network", detail: "2.4 GHz is usually more crowded and common on low-trust public Wi-Fi.", level: .caution))
            }

            let detail = insecureNearby == 0
                ? "The nearby Wi-Fi environment looks fairly clean."
                : "Found \(insecureNearby) open or weak nearby networks, which pushes the environment grade down."

            return makeFactor(title: "Environment", points: points, maxPoints: 15, detail: detail)
        }()
        factors.append(environmentFactor)

        if issues.isEmpty {
            issues.append(SafetyIssue(title: "No obvious hotspot red flags", detail: "Encryption, gateway, and DNS checks all look normal.", level: .safe))
        }

        let score = max(0, min(100, factors.reduce(0) { $0 + $1.points }))
        let confidence = confidenceScore(current: current, gateway: gateway, dnsServers: dnsServers, nearbyNetworks: nearbyNetworks)
        let hardUnsafe = security.contains("none") || security.contains("open") || security.contains("wep") || (!gateway.isEmpty && !isPrivateAddress(gateway) && !isHotspot)

        let trustLevel: TrustLevel
        if hardUnsafe || score < 50 {
            trustLevel = .avoid
        } else if score < 78 {
            trustLevel = .caution
        } else {
            trustLevel = .safe
        }

        let weakFactors = factors
            .sorted { $0.progress < $1.progress }
            .prefix(2)
            .map(\.title)

        let guidanceTitle: String
        if hardUnsafe {
            guidanceTitle = "Not fine for sensitive use"
        } else if captivePortal {
            guidanceTitle = "Use after portal clears"
        } else if isHotspot && score >= 74 {
            guidanceTitle = "Hotspot looks fine"
        } else if score >= 86 {
            guidanceTitle = "Fine for normal use"
        } else if score >= 70 {
            guidanceTitle = "Fine, not ideal"
        } else if score >= 55 {
            guidanceTitle = "Light use only"
        } else {
            guidanceTitle = "Avoid sensitive work"
        }

        let guidancePrefix: String
        switch guidanceTitle {
        case "Not fine for sensitive use":
            guidancePrefix = "A real trust blocker was detected."
        case "Use after portal clears":
            guidancePrefix = "This looks like a venue-style network and the portal is still in the way."
        case "Hotspot looks fine":
            guidancePrefix = "This appears to be your own hotspot."
        case "Fine for normal use":
            guidancePrefix = "No major blockers were detected."
        case "Fine, not ideal":
            guidancePrefix = "This network is generally usable."
        case "Light use only":
            guidancePrefix = "This network is usable, but the grade is being pulled down."
        default:
            guidancePrefix = "The trust picture is weak."
        }

        let guidanceDetail = weakFactors.isEmpty
            ? guidancePrefix
            : "\(guidancePrefix) Main drag: \(weakFactors.joined(separator: " + "))."

        return ScoreAssessment(
            score: score,
            confidence: confidence,
            trustLevel: trustLevel,
            guidanceTitle: guidanceTitle,
            guidanceDetail: guidanceDetail,
            factors: factors,
            issues: issues
        )
    }

    func makeFactor(title: String, points: Int, maxPoints: Int, detail: String) -> ScoreFactor {
        let boundedPoints = max(0, min(maxPoints, points))
        let ratio = maxPoints > 0 ? Double(boundedPoints) / Double(maxPoints) : 0
        let level: TrustLevel
        if ratio >= 0.8 {
            level = .safe
        } else if ratio >= 0.55 {
            level = .caution
        } else {
            level = .avoid
        }

        return ScoreFactor(title: title, points: boundedPoints, maxPoints: maxPoints, level: level, detail: detail)
    }

    func confidenceScore(
        current: ParsedCurrentNetwork,
        gateway: String,
        dnsServers: [String],
        nearbyNetworks: [NearbyNetwork]
    ) -> Int {
        var confidence = 100
        if current.security == "Unknown" { confidence -= 14 }
        if current.channel == "--" { confidence -= 12 }
        if current.signal == nil { confidence -= 10 }
        if current.noise == nil { confidence -= 5 }
        if gateway.isEmpty { confidence -= 10 }
        if dnsServers.isEmpty { confidence -= 10 }
        if nearbyNetworks.isEmpty { confidence -= 8 }
        return max(55, min(100, confidence))
    }

    func bandLabel(from channel: String) -> String {
        if channel.contains("6GHz") { return "6 GHz" }
        if channel.contains("5GHz") { return "5 GHz" }
        if channel.contains("2GHz") { return "2.4 GHz" }
        return "?"
    }

    func riskProbability(security: String, channel: String, signal: Int?) -> Int {
        var risk = 20
        let lower = security.lowercased()

        if lower.contains("open") || lower.contains("none") {
            risk += 55
        } else if lower.contains("wep") {
            risk += 45
        } else if lower.contains("wpa2") && !lower.contains("wpa3") {
            risk += 18
        } else if lower.contains("wpa3") {
            risk -= 8
        }

        if channel.contains("2GHz") {
            risk += 10
        }

        if let signal {
            switch signal {
            case -55...0:
                risk -= 4
            case -67 ..< -55:
                break
            case -75 ..< -67:
                risk += 8
            default:
                risk += 14
            }
        }

        return max(1, min(99, risk))
    }

    func estimatedDistance(from signal: Int?) -> String {
        guard let signal else { return "Unknown" }
        switch signal {
        case -50...0:
            return "~1-3 m"
        case -60 ..< -50:
            return "~3-7 m"
        case -67 ..< -60:
            return "~5-12 m"
        case -75 ..< -67:
            return "~10-20 m"
        default:
            return "20 m+"
        }
    }

    private func isPlausibleIPAddress(_ value: String) -> Bool {
        let isIPv4 = value.range(of: #"^\d{1,3}(\.\d{1,3}){3}$"#, options: .regularExpression) != nil
        let isIPv6 = value.range(of: #"^[0-9A-Fa-f:]+$"#, options: .regularExpression) != nil && value.contains(":")
        return isIPv4 || isIPv6
    }

    private func isPrivateAddress(_ value: String) -> Bool {
        value.hasPrefix("10.") || value.hasPrefix("192.168.") || value.range(of: #"^172\.(1[6-9]|2\d|3[0-1])\."#, options: .regularExpression) != nil
    }
}
