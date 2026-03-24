import AppIntents
import SwiftUI
import VibeWidgetCore
import WidgetKit

struct VibeEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct VibeProvider: TimelineProvider {
    func placeholder(in context: Context) -> VibeEntry {
        VibeEntry(date: .now, snapshot: WidgetSnapshot(
            nowPlaying: MusicNowPlaying(title: "Afterglow Arcade", artist: "North Static", source: "Spotify", isPlaying: true),
            topRecommendation: VibeRecommendation(title: "Shimmer Driver", artist: "Lune Avenue", subtitle: "Fresh pop night drive", reason: "Close to your cool-mix brief."),
            routeStatus: AudioRouteStatus(preferredOutput: "PartyBox", currentOutput: "PartyBox 310", availability: .connected),
            lightSummary: "Bedroom lights dimmed",
            lastActionResult: "Pinned a new top vibe."
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (VibeEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VibeEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .after(.now.addingTimeInterval(900))))
    }

    private func entry() -> VibeEntry {
        VibeEntry(date: .now, snapshot: SharedStore.shared.loadSnapshot())
    }
}

struct VibeStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VibeStatusWidget", provider: VibeProvider()) { entry in
            VibeStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("VibeWidget")
        .description("Glanceable speaker, lights, and top-vibe controls.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct VibeStatusWidgetView: View {
    let entry: VibeEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current vibe")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(entry.snapshot.nowPlaying.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(entry.snapshot.nowPlaying.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                routeBadge
            }

            if family == .systemLarge, let recommendation = entry.snapshot.topRecommendation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pinned next")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(recommendation.title)
                        .font(.subheadline.weight(.semibold))
                    Text(recommendation.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                WidgetActionChip(title: "Dim", intent: DimBedroomIntent())
                WidgetActionChip(title: "Rain", intent: SetRainIntent())
                WidgetActionChip(title: "Mix", intent: RefreshRecommendationsIntent())
                WidgetActionChip(title: "Panel", intent: OpenVibePanelIntent())
            }

            Spacer(minLength: 0)

            Text(entry.snapshot.lightSummary)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(entry.snapshot.lastActionResult)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.05, green: 0.07, blue: 0.12), Color(red: 0.12, green: 0.09, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var routeBadge: some View {
        Text(routeLabel)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(routeColor.opacity(0.18)))
            .foregroundStyle(routeColor)
    }

    private var routeLabel: String {
        switch entry.snapshot.routeStatus.availability {
        case .connected:
            return "PartyBox on"
        case .available:
            return "Switch output"
        case .missing:
            return "Speaker missing"
        }
    }

    private var routeColor: Color {
        switch entry.snapshot.routeStatus.availability {
        case .connected:
            return .green
        case .available:
            return .orange
        case .missing:
            return .red
        }
    }
}

private struct WidgetActionChip<I: AppIntent>: View {
    let title: String
    let intent: I

    var body: some View {
        Button(intent: intent) {
            Text(title)
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct SetRainIntent: AppIntent, QueuedWidgetIntent {
    static let title: LocalizedStringResource = "Rain"
    static let description = IntentDescription("Open the app and start a rain-sounds vibe.")
    static let openAppWhenRun = true

    var action: QueuedWidgetAction { QueuedWidgetAction(kind: .rain) }

    func perform() async throws -> some IntentResult {
        enqueueAction()
        return .result()
    }
}
