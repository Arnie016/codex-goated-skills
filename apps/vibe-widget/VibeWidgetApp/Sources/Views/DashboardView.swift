import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                actionStrip
                recommendationStack
                statusGrid
            }
            .padding(.vertical, 18)
        }
    }

    private var hero: some View {
        GlassPanel {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current vibe")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(model.widgetSnapshot.nowPlaying.title)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))

                    Text(model.widgetSnapshot.nowPlaying.artist)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(model.widgetSnapshot.lastActionResult)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    StatusBadge(title: model.widgetSnapshot.routeStatus.preferredOutput, subtitle: model.widgetSnapshot.routeStatus.currentOutput, availability: model.widgetSnapshot.routeStatus.availability)
                    Button("Open AI Panel") {
                        model.isPanelPresented = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var actionStrip: some View {
        HStack(spacing: 14) {
            QuickActionButton(title: "Dim Bedroom", subtitle: "Night lights", systemImage: "lightbulb.max") {
                model.performQuickAction(.dimBedroom)
            }
            QuickActionButton(title: "Rain", subtitle: "Weather loop", systemImage: "cloud.rain") {
                model.performQuickAction(.rain)
            }
            QuickActionButton(title: "Cool Mix", subtitle: "Fresh picks", systemImage: "sparkles") {
                model.performQuickAction(.refreshRecommendations)
            }
            QuickActionButton(title: "Play Top Pick", subtitle: "Autoplay", systemImage: "speaker.wave.2") {
                model.performQuickAction(.playRecommended)
            }
        }
    }

    private var recommendationStack: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Pinned picks")
                        .font(.title2.weight(.bold))
                    Spacer()
                    Button("Refresh") {
                        model.performQuickAction(.refreshRecommendations)
                    }
                    .buttonStyle(.borderless)
                }

                if model.recommendations.isEmpty {
                    Text("Your fresh recommendations will appear here after the first vibe query.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.recommendations) { recommendation in
                        RecommendationRow(recommendation: recommendation, isPinned: recommendation.id == model.topRecommendation?.id)
                    }
                }
            }
        }
    }

    private var statusGrid: some View {
        HStack(alignment: .top, spacing: 16) {
            GlassPanel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Lighting")
                        .font(.headline)
                    Text(model.widgetSnapshot.lightSummary)
                        .font(.title3.weight(.medium))
                    Text("Default room: \(model.settings.defaultRoomName)")
                        .foregroundStyle(.secondary)
                }
            }

            GlassPanel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Speaker route")
                        .font(.headline)
                    Text(model.widgetSnapshot.routeStatus.currentOutput)
                        .font(.title3.weight(.medium))
                    HStack {
                        Button("Sound Settings") {
                            model.openSoundSettings()
                        }
                        .buttonStyle(.bordered)

                        Button("Bluetooth") {
                            model.openBluetoothSettings()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            GlassPanel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Voice status")
                        .font(.headline)
                    Text(model.isListening ? "Listening now" : "Idle")
                        .font(.title3.weight(.medium))
                    Text(model.statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
