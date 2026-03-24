import AppKit
import SwiftUI

private enum WatchtowerPalette {
    static let backgroundTop = Color(red: 0.08, green: 0.09, blue: 0.12)
    static let backgroundBottom = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let card = Color(red: 0.12, green: 0.13, blue: 0.17).opacity(0.96)
    static let raised = Color(red: 0.15, green: 0.16, blue: 0.20).opacity(0.98)
    static let border = Color.white.opacity(0.08)
    static let primaryText = Color.white.opacity(0.96)
    static let secondaryText = Color(red: 0.80, green: 0.84, blue: 0.89)
    static let mutedText = Color.white.opacity(0.62)
}

struct MenuBarView: View {
    @ObservedObject var model: WatchtowerModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    WatchtowerPalette.backgroundTop,
                    model.snapshot.trustLevel.color.opacity(0.12),
                    WatchtowerPalette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    heroCard
                    driversSection
                    nearbySection
                    footer
                }
                .padding(16)
            }
            .frame(width: 372, height: 530)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("WiFi Watchtower")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(WatchtowerPalette.primaryText)
                Text(model.snapshot.networkName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WatchtowerPalette.secondaryText)
            }

            Spacer()

            Button {
                model.refresh()
            } label: {
                Image(systemName: model.isRefreshing ? "wifi.circle.fill" : "arrow.clockwise")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(WatchtowerPalette.primaryText)
            }
            .buttonStyle(.borderless)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: model.snapshot.trustLevel.symbolName)
                            .foregroundStyle(model.snapshot.scoreAccent)
                        Text(model.snapshot.trustLevel.title)
                            .font(.title3.weight(.black))
                            .foregroundStyle(WatchtowerPalette.primaryText)
                    }

                    Text(model.snapshot.shortRecommendation)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(model.snapshot.scoreAccent)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Score")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(WatchtowerPalette.mutedText)
                    Text("\(model.snapshot.score)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(WatchtowerPalette.primaryText)
                }
            }

            HStack(spacing: 8) {
                infoChip(model.snapshot.security, tint: .white.opacity(0.16))
                infoChip(model.snapshot.bandLabel, tint: .white.opacity(0.1))
                infoChip("\(model.snapshot.confidence)% conf", tint: .white.opacity(0.1))
                if let badge = model.snapshot.connectionBadgeText {
                    infoChip(badge, tint: Color.orange.opacity(0.16), foreground: .orange)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                metricTile("Signal", value: model.snapshot.signal.map { "\($0) dBm" } ?? "--", detail: model.snapshot.signalLabel)
                metricTile("Gateway", value: model.snapshot.gateway.isEmpty ? "Unknown" : model.snapshot.gateway, detail: "Router")
                metricTile("DNS", value: model.snapshot.dnsServers.first ?? "Unknown", detail: model.snapshot.dnsServers.count > 1 ? "\(model.snapshot.dnsServers.count) servers" : "Resolver")
                metricTile("Portal", value: model.snapshot.captivePortal ? "Detected" : "Clear", detail: model.snapshot.nearbySummary)
            }

            signalBar
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(WatchtowerPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(model.snapshot.scoreAccent.opacity(0.9), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.28), radius: 22, y: 12)
    }

    private var signalBar: some View {
        HStack(spacing: 5) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(index < model.snapshot.signalBars ? model.snapshot.scoreAccent : .white.opacity(0.12))
                    .frame(width: 24, height: CGFloat(8 + (index * 4)))
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }

            Spacer()

            Text(model.snapshot.subheadline)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WatchtowerPalette.secondaryText)
        }
        .frame(height: 24, alignment: .bottom)
    }

    private var driversSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Why This Grade", trailing: "\(model.snapshot.confidence)% confidence")
            compactNotice(model.snapshot.scoreSummary)

            if model.snapshot.scoreFactors.isEmpty {
                compactNotice("No grading factors yet.")
            } else {
                ForEach(model.snapshot.scoreFactors) { factor in
                    factorRow(factor)
                }
            }
        }
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Nearby Wi-Fi")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WatchtowerPalette.secondaryText)
                Spacer()
                infoChip("\(model.snapshot.totalNearbyCount) total", tint: .white.opacity(0.08))
                infoChip("\(model.snapshot.saferNearbyCount) safer", tint: Color.green.opacity(0.14), foreground: .green)
                infoChip("\(model.snapshot.riskyNearbyCount) risky", tint: Color.orange.opacity(0.16), foreground: .orange)
            }

            if model.snapshot.nearbyNetworks.isEmpty {
                compactNotice("No nearby scan results yet.")
            } else {
                ForEach(model.snapshot.nearbyNetworks.prefix(4)) { network in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(network.isRisky ? Color.orange : .green)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(network.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(WatchtowerPalette.primaryText)
                            Text("\(network.security) • \(network.band) • \(network.type)")
                                .font(.caption)
                                .foregroundStyle(WatchtowerPalette.secondaryText)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(network.riskProbability)% risk")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(network.isRisky ? .orange : .green)
                            Text(network.estimatedDistance)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(WatchtowerPalette.mutedText)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(WatchtowerPalette.raised)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(WatchtowerPalette.border, lineWidth: 1)
                            )
                    )
                    .help("\(network.name)\nSecurity: \(network.security)\nBand: \(network.band)\nChannel: \(network.channel)\nType: \(network.type)\nEstimated distance: \(network.estimatedDistance)\nRisk probability: \(network.riskProbability)%")
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button("Refresh") {
                model.refresh()
            }
            .buttonStyle(.borderedProminent)

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(WatchtowerPalette.secondaryText)

            Spacer()
        }
        .padding(.top, 2)
    }

    private func sectionHeader(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(WatchtowerPalette.secondaryText)
            Spacer()
            Text(trailing)
                .font(.caption.weight(.bold))
                .foregroundStyle(WatchtowerPalette.mutedText)
        }
    }

    private func infoChip(_ text: String, tint: Color, foreground: Color = .white) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.95))
            )
    }

    private func metricTile(_ title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(WatchtowerPalette.mutedText)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(WatchtowerPalette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(detail)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WatchtowerPalette.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WatchtowerPalette.raised)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WatchtowerPalette.border, lineWidth: 1)
                )
        )
        .help(metricHelpText(title: title, value: value, detail: detail))
    }

    private func compactNotice(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(WatchtowerPalette.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(WatchtowerPalette.raised)
            )
    }

    private func factorRow(_ factor: ScoreFactor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(factor.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WatchtowerPalette.primaryText)

                Spacer()

                Text(factor.label)
                    .font(.caption.weight(.black))
                    .foregroundStyle(factor.level.color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.08))
                    Capsule(style: .continuous)
                        .fill(factor.level.color)
                        .frame(width: max(10, geometry.size.width * factor.progress))
                }
            }
            .frame(height: 7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(WatchtowerPalette.raised)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(WatchtowerPalette.border, lineWidth: 1)
                )
        )
        .help("\(factor.title): \(factor.label)\n\(factor.detail)")
    }

    private func metricHelpText(title: String, value: String, detail: String) -> String {
        switch title {
        case "DNS":
            return "DNS: \(value)\nThis is the resolver your Mac is using to turn site names into IP addresses.\n\(detail)"
        case "Gateway":
            return "Gateway: \(value)\nThis is the router or hotspot your Mac is sending internet traffic through.\n\(detail)"
        case "Signal":
            return "Signal: \(value)\nHigher strength usually means a more stable nearby connection.\n\(detail)"
        case "Portal":
            return "Portal: \(value)\nThis checks for captive portal behavior like hotel or airport sign-in pages.\n\(detail)"
        default:
            return "\(title): \(value)\n\(detail)"
        }
    }
}
