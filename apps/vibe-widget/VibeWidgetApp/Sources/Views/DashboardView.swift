import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                actionStrip
                contextStudio
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
                    HStack(spacing: 10) {
                        Button("Open AI Panel") {
                            model.presentPanel(route: .vibe)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Context Studio") {
                            model.presentPanel(route: .context)
                        }
                        .buttonStyle(.bordered)
                    }
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
            QuickActionButton(title: "Discover", subtitle: "Current song", systemImage: "sparkles") {
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Discovery lanes")
                            .font(.title2.weight(.bold))
                        Text("Fresh Spotify tracks built from whatever you are listening to right now.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if model.isRefreshingDiscovery {
                        ProgressView()
                            .scaleEffect(0.85)
                    }
                    Button("Refresh") {
                        model.performQuickAction(.refreshRecommendations)
                    }
                    .buttonStyle(.borderless)
                }

                if model.discoveryLanes.isEmpty {
                    Text("Play something in Spotify and refresh to build discovery lanes.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.discoveryLanes) { lane in
                        DiscoveryLaneRow(lane: lane, isPinned: lane.recommendation.id == model.topRecommendation?.id) {
                            model.playDiscoveryLane(lane)
                        }
                    }
                }
            }
        }
    }

    private var contextStudio: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context studio")
                            .font(.title2.weight(.bold))
                        Text("Build a local RAG-style pack from dropped files, estimate token usage instantly, and preview what retrieval would bring forward.")
                            .foregroundStyle(.secondary)
                        Text(model.contextStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        MetricCapsule(label: "Files", value: "\(model.contextLibrary.documents.count)")
                        MetricCapsule(label: "Tokens", value: model.contextTokenSummary)
                        MetricCapsule(label: "Chunks", value: "\(model.contextLibrary.totalEstimatedChunks)")
                    }
                }

                HStack(spacing: 12) {
                    Button("Open Context Studio") {
                        model.presentPanel(route: .context)
                    }
                    .buttonStyle(.borderedProminent)

                    if !model.contextLibrary.documents.isEmpty {
                        Button("Clear Pack") {
                            model.clearContextLibrary()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if model.contextDocuments.isEmpty {
                    Text("No documents indexed yet. Drop a folder from this repo into the popup and the token estimates will show up right away.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(model.contextDocuments.prefix(3))) { document in
                        ContextDocumentCompactRow(document: document)
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
