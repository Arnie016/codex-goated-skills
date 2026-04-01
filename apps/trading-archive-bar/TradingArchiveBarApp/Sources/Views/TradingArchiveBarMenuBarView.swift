import SwiftUI

struct TradingArchiveBarMenuBarView: View {
    @ObservedObject var model: TradingArchiveBarAppModel

    private let metricColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ZStack {
            TradingArchiveBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    headerCard
                    controlsCard
                    sourcesCard
                    articlesCard
                    footerCard
                }
                .padding(10)
                .frame(width: 440)
            }
            .scrollIndicators(.hidden)
        }
        .font(.system(size: 12))
        .controlSize(.small)
    }

    private var headerCard: some View {
        TradingArchiveCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [TradingArchivePalette.accent, TradingArchivePalette.accentSoft],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: model.menuBarSymbolName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Trading Archive")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(TradingArchivePalette.primaryText)
                            TradingArchiveStatusPill(title: model.loadState.title, tint: tint(for: model.loadState))
                        }

                        Text("Research archive for trading reads")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(TradingArchivePalette.primaryText)

                        Text(model.dashboardLine)
                            .font(.system(size: 11))
                            .foregroundStyle(TradingArchivePalette.secondaryText)
                            .lineLimit(3)
                    }
                }

                LazyVGrid(columns: metricColumns, spacing: 8) {
                    ForEach(model.metricTiles) { metric in
                        TradingArchiveMetricTile(metric: metric)
                    }
                }
            }
        }
    }

    private var controlsCard: some View {
        TradingArchiveCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    searchField
                    Button("Refresh") {
                        Task { await model.refresh(force: true) }
                    }
                    .buttonStyle(TradingArchivePrimaryButtonStyle())
                    .frame(width: 90)
                }

                HStack(spacing: 8) {
                    ForEach(TradingArchiveWindow.allCases) { window in
                        TradingArchiveWindowButton(
                            window: window,
                            isActive: model.window == window,
                            action: { model.window = window }
                        )
                    }
                }

                HStack(spacing: 8) {
                    Button("Copy Queue") { model.copyReadingQueue() }
                        .buttonStyle(TradingArchiveSecondaryButtonStyle())
                    SettingsLink {
                        Text("Settings")
                    }
                    .buttonStyle(TradingArchiveSecondaryButtonStyle())
                }
            }
        }
    }

    private var sourcesCard: some View {
        TradingArchiveCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Sources")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TradingArchivePalette.primaryText)
                    Spacer(minLength: 0)
                    Text("\(model.sourceStatuses.count) configured")
                        .font(.system(size: 10.5))
                        .foregroundStyle(TradingArchivePalette.secondaryText)
                }

                if model.sourceStatuses.isEmpty {
                    Text("No feeds yet. Open Settings and paste one RSS or Atom URL per line to start building the archive.")
                        .font(.system(size: 11))
                        .foregroundStyle(TradingArchivePalette.secondaryText)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(model.sourceStatuses) { status in
                                TradingArchiveSourceBadge(status: status) {
                                    model.openSource(status)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var articlesCard: some View {
        TradingArchiveCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Archive Queue")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TradingArchivePalette.primaryText)
                    Spacer(minLength: 0)
                    Stepper(value: storyLimitBinding, in: 10...80, step: 5) {
                        Text("\(model.storyLimit) shown")
                            .font(.system(size: 10.5))
                            .foregroundStyle(TradingArchivePalette.secondaryText)
                    }
                    .labelsHidden()
                }

                if model.visibleArticles.isEmpty {
                    Text(emptyMessage)
                        .font(.system(size: 11.5))
                        .foregroundStyle(TradingArchivePalette.secondaryText)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(TradingArchivePalette.border, lineWidth: 1)
                                )
                        )
                } else {
                    ForEach(model.visibleArticles) { article in
                        TradingArchiveArticleRow(
                            article: article,
                            isFavorite: model.isFavorite(article),
                            favoriteAction: { model.toggleFavorite(article) },
                            openAction: { model.openArticle(article) }
                        )
                    }
                }
            }
        }
    }

    private var footerCard: some View {
        TradingArchiveCard {
            VStack(alignment: .leading, spacing: 8) {
                if let feedback = model.feedbackMessage {
                    Text(feedback)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(TradingArchivePalette.accentSoft)
                }

                Text(model.noteLine)
                    .font(.system(size: 10.5))
                    .foregroundStyle(TradingArchivePalette.secondaryText)

                Text("This archive uses public RSS or Atom feeds that you configure. It is not a broker integration or market data terminal.")
                    .font(.system(size: 10))
                    .foregroundStyle(TradingArchivePalette.mutedText)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(TradingArchivePalette.secondaryText)
            TextField("Search titles, notes, tags, or sources", text: $model.query)
                .textFieldStyle(.plain)
                .foregroundStyle(TradingArchivePalette.primaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(TradingArchivePalette.border, lineWidth: 1)
                )
        )
    }

    private var storyLimitBinding: Binding<Int> {
        Binding(
            get: { model.storyLimit },
            set: { model.storyLimit = $0 }
        )
    }

    private var emptyMessage: String {
        if model.sourceStatuses.isEmpty {
            return "Add feed URLs in Settings to build the archive."
        }
        if !model.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No archived articles match your current search."
        }
        return "No archived articles match this filter yet."
    }

    private func tint(for state: TradingArchiveLoadState) -> Color {
        switch state {
        case .live:
            return TradingArchivePalette.accent
        case .syncing:
            return TradingArchivePalette.warning
        case .cached:
            return TradingArchivePalette.warning
        case .error:
            return TradingArchivePalette.danger
        case .empty:
            return TradingArchivePalette.cardStrong
        }
    }
}
