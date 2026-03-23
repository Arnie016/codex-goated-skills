import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: WatchtowerModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    model.snapshot.trustLevel.color.opacity(0.24),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    statsGrid
                    issuePanel
                    nearbyPanel
                }
                .padding(28)
            }
        }
        .task {
            model.refresh()
        }
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("WiFi Watchtower")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                Text("Checks your current Wi-Fi and explains whether it looks safe, cautionary, or risky.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    capsuleLabel(model.snapshot.trustLevel.title, color: model.snapshot.trustLevel.color)
                    capsuleLabel("Trust score \(model.snapshot.score) / 100", color: Color.black.opacity(0.75))
                    capsuleLabel(model.snapshot.networkName, color: Color.blue.opacity(0.8))
                }

                Text(model.snapshot.scoreSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Recommendation: \(model.snapshot.shortRecommendation)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(model.snapshot.trustLevel.color)
            }

            Spacer()

            Button {
                model.refresh()
            } label: {
                Label("Refresh Scan", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            dashboardCard("Security", value: model.snapshot.security, subtitle: model.snapshot.phyMode)
            dashboardCard("Channel", value: model.snapshot.channel, subtitle: model.snapshot.signalNoiseSummary)
            dashboardCard("Gateway", value: model.snapshot.gateway.isEmpty ? "Unknown" : model.snapshot.gateway, subtitle: "Default route")
            dashboardCard("DNS", value: model.snapshot.dnsServers.first ?? "Unknown", subtitle: "\(model.snapshot.dnsServers.count) server(s)")
        }
    }

    private var issuePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Trust Breakdown")
                .font(.title3.weight(.bold))
            Text("These are the main reasons behind the current trust score.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(model.snapshot.issues) { issue in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: issue.level.symbolName)
                        .foregroundStyle(issue.level.color)
                        .font(.title3)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(issue.title)
                            .font(.headline)
                        Text(issue.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.7))
                )
            }
        }
    }

    private var nearbyPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Nearby Wi-Fi Risk")
                    .font(.title3.weight(.bold))
                Spacer()
                Text("\(model.snapshot.nearbyInsecureCount) insecure nearby")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(model.snapshot.nearbyInsecureCount == 0 ? Color.secondary : Color.orange)
            }

            Text("This section looks at nearby open or weakly secured hotspots and uses that as extra context, not proof that your current network is compromised.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(model.snapshot.nearbyNetworks) { network in
                HStack {
                    Text(network.security)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(network.channel)
                        .foregroundStyle(.secondary)
                    Text(network.type)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.66))
                )
            }
        }
    }

    private func dashboardCard(_ title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.8))
        )
    }

    private func capsuleLabel(_ value: String, color: Color) -> some View {
        Text(value)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.12))
            )
            .foregroundStyle(color)
    }
}
