import Foundation
import Network

enum XboxLinks {
    static let cloudGaming = URL(string: "https://www.xbox.com/play")!
    static let remotePlay = URL(string: "https://www.xbox.com/remoteplay")!
    static let account = URL(string: "https://account.xbox.com/")!
    static let support = URL(string: "https://support.xbox.com/")!
    static let applePairingGuide = URL(string: "https://support.apple.com/en-euro/111101")!
    static let controllerGuide = URL(string: "https://support.xbox.com/en-US/help/hardware-network/controller/update-xbox-wireless-controller")!
}

final class XboxConnectivityService {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "XboxStudio.NetworkMonitor")
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    init() {
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    @MainActor
    func captureSnapshot() async -> XboxConnectivitySnapshot {
        let cloudProbe = await probe(name: "Cloud Gaming", destination: "xbox.com/play", url: XboxLinks.cloudGaming)
        let remoteProbe = await probe(name: "Remote Play", destination: "xbox.com/remoteplay", url: XboxLinks.remotePlay)
        let accountProbe = await probe(name: "Account", destination: "account.xbox.com", url: XboxLinks.account)

        let probes = [cloudProbe, remoteProbe, accountProbe]
        let path = monitor.currentPath

        let reachableCount = probes.filter { $0.status == .good }.count
        let warningCount = probes.filter { $0.status == .warning }.count
        let overallLevel: XboxStatusLevel
        if path.status != .satisfied || reachableCount == 0 {
            overallLevel = .critical
        } else if warningCount > 0 {
            overallLevel = .warning
        } else {
            overallLevel = .good
        }

        let pathSummary: String
        switch path.status {
        case .satisfied:
            if path.isExpensive {
                pathSummary = "Network is online on a metered path."
            } else if path.isConstrained {
                pathSummary = "Network is online with Low Data Mode constraints."
            } else {
                pathSummary = "Network is online and Xbox web surfaces are reachable."
            }
        case .requiresConnection:
            pathSummary = "The Mac needs a connection before Xbox pages can load."
        default:
            pathSummary = "The Mac is offline or blocked from Xbox web surfaces."
        }

        let detail = interfaceSummary(for: path)
        let timestamp = formatter.string(from: Date())

        return XboxConnectivitySnapshot(
            headline: pathSummary,
            detail: detail,
            level: overallLevel,
            probes: probes,
            checkedAtLabel: "Updated \(timestamp)"
        )
    }

    private func interfaceSummary(for path: NWPath) -> String {
        var parts: [String] = []
        if path.usesInterfaceType(.wifi) {
            parts.append("Wi-Fi")
        }
        if path.usesInterfaceType(.wiredEthernet) {
            parts.append("Ethernet")
        }
        if path.usesInterfaceType(.cellular) {
            parts.append("Cellular")
        }
        if parts.isEmpty {
            parts.append("Unknown interface")
        }
        if path.isExpensive {
            parts.append("metered")
        }
        if path.isConstrained {
            parts.append("low-data")
        }
        return parts.joined(separator: " • ")
    }

    @MainActor
    private func probe(name: String, destination: String, url: URL) async -> XboxEndpointProbe {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("XboxStudio/1.0", forHTTPHeaderField: "User-Agent")

        let startedAt = Date()

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let elapsed = Int(Date().timeIntervalSince(startedAt) * 1000)
            guard let httpResponse = response as? HTTPURLResponse else {
                return XboxEndpointProbe(
                    name: name,
                    destination: destination,
                    status: .warning,
                    summary: "Unexpected response",
                    detail: "Response arrived without an HTTP status."
                )
            }

            let status: XboxStatusLevel
            let summary: String
            switch httpResponse.statusCode {
            case 200..<400:
                status = .good
                summary = "Reachable in \(elapsed) ms"
            case 400..<500:
                status = .warning
                summary = "Page responded with \(httpResponse.statusCode)"
            default:
                status = .critical
                summary = "Server responded with \(httpResponse.statusCode)"
            }

            return XboxEndpointProbe(
                name: name,
                destination: destination,
                status: status,
                summary: summary,
                detail: "HTTP \(httpResponse.statusCode)"
            )
        } catch {
            return XboxEndpointProbe(
                name: name,
                destination: destination,
                status: .critical,
                summary: "Unavailable",
                detail: error.localizedDescription
            )
        }
    }
}
