import SwiftUI

struct MinefieldMenuBarView: View {
    @StateObject private var game = MinefieldGame()
    @State private var showsBuildNotes = false

    @AppStorage("minefield-menubar.best-time") private var bestTime = 0.0
    @AppStorage("minefield-menubar.win-streak") private var winStreak = 0
    @AppStorage("minefield-menubar.best-streak") private var bestStreak = 0

    private let sections = MinefieldDetailView.previewSections
    private let columns = Array(repeating: GridItem(.fixed(32), spacing: 4), count: MinefieldGame.columns)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statRow
            modeRow
            board
            footer
            buildNotes
        }
        .padding(16)
        .frame(width: 360)
        .background(MinefieldTheme.background)
        .onChange(of: game.outcome) { _, newValue in
            switch newValue {
            case .won:
                winStreak += 1
                bestStreak = max(bestStreak, winStreak)
                let elapsed = game.elapsedTime(at: game.finishedAt ?? .now)
                if bestTime == 0 || elapsed < bestTime {
                    bestTime = elapsed
                }
            case .lost:
                winStreak = 0
            case .ready, .inProgress:
                break
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: headerSymbolName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(headerColor)
                    Text(headerTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MinefieldTheme.textPrimary)
                }

                Text(statusLine)
                    .font(.subheadline)
                    .foregroundStyle(MinefieldTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                game.reset()
            } label: {
                Label("New", systemImage: "arrow.clockwise")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(MinefieldTheme.accent)
        }
    }

    private var statRow: some View {
        HStack(spacing: 8) {
            StatCard(title: "Mines", value: "\(game.remainingMineEstimate)", systemImage: "diamond.fill", accent: MinefieldTheme.warning)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                StatCard(
                    title: "Time",
                    value: timeString(from: game.elapsedTime(at: context.date)),
                    systemImage: "timer",
                    accent: MinefieldTheme.accent
                )
            }

            StatCard(
                title: "Best",
                value: bestTime == 0 ? "--:--" : timeString(from: bestTime),
                systemImage: "trophy.fill",
                accent: MinefieldTheme.gold
            )
        }
    }

    private var modeRow: some View {
        HStack(spacing: 8) {
            ForEach(MinefieldInteractionMode.allCases) { mode in
                Button {
                    game.mode = mode
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 12, weight: .bold))
                        Text(mode.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(game.mode == mode ? Color.black : MinefieldTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(game.mode == mode ? MinefieldTheme.accent : MinefieldTheme.panel)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(game.mode == mode ? MinefieldTheme.accentSoft.opacity(0.3) : MinefieldTheme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var board: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(game.tiles) { tile in
                Button {
                    game.handleSelection(for: tile.id)
                } label: {
                    tileFace(tile)
                        .frame(width: 32, height: 32)
                        .background(tileBackground(for: tile), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(tileBorder(for: tile), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tileAccessibilityLabel(tile))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MinefieldTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MinefieldTheme.border, lineWidth: 1)
        )
    }

    private var footer: some View {
        HStack(spacing: 10) {
            FooterPill(
                title: "Moves",
                value: "\(game.moveCount)"
            )
            FooterPill(
                title: "Streak",
                value: "\(winStreak)"
            )
            FooterPill(
                title: "Best streak",
                value: "\(bestStreak)"
            )
            Spacer(minLength: 0)
            Text("\(game.safeTilesRemaining) safe left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MinefieldTheme.textSecondary)
        }
    }

    private var buildNotes: some View {
        DisclosureGroup(isExpanded: $showsBuildNotes) {
            MinefieldDetailView(sections: sections)
                .padding(.top, 10)
        } label: {
            Text("Why this works in the menu bar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MinefieldTheme.textPrimary)
        }
        .tint(MinefieldTheme.accent)
    }

    private var headerTitle: String {
        switch game.outcome {
        case .ready:
            return "Minefield ready"
        case .inProgress:
            return "Keep the lane clean"
        case .won:
            return "Board cleared"
        case .lost:
            return "Mine hit"
        }
    }

    private var statusLine: String {
        switch game.outcome {
        case .ready:
            return "First reveal is always safe. Flip to Flag mode when you want to mark a suspected tile."
        case .inProgress:
            return game.safeTilesRemaining == 1
                ? "One safe tile left. Stay off the mine."
                : "\(game.safeTilesRemaining) safe tiles left. Keep scanning for patterns."
        case .won:
            return "Clean sweep. Hit New and keep the streak moving."
        case .lost:
            return "The triggered mine is highlighted. Reset and run it back."
        }
    }

    private var headerSymbolName: String {
        switch game.outcome {
        case .ready:
            return "diamond.fill"
        case .inProgress:
            return game.mode == .reveal ? "sparkle.magnifyingglass" : "flag.fill"
        case .won:
            return "checkmark.seal.fill"
        case .lost:
            return "burst.fill"
        }
    }

    private var headerColor: Color {
        switch game.outcome {
        case .ready, .inProgress:
            return MinefieldTheme.accent
        case .won:
            return MinefieldTheme.gold
        case .lost:
            return MinefieldTheme.warning
        }
    }

    @ViewBuilder
    private func tileFace(_ tile: MinefieldTile) -> some View {
        switch tile.state {
        case .hidden:
            Image(systemName: "circle.fill")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(MinefieldTheme.textSecondary.opacity(0.45))
        case .flagged:
            Image(systemName: "flag.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.88))
        case .revealed:
            if tile.hasMine {
                Image(systemName: tile.isTriggeredMine ? "burst.fill" : "diamond.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tile.isTriggeredMine ? Color.white : Color.black.opacity(0.88))
            } else if tile.adjacentMineCount > 0 {
                Text("\(tile.adjacentMineCount)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MinefieldTheme.numberColor(tile.adjacentMineCount))
            } else {
                EmptyView()
            }
        }
    }

    private func tileBackground(for tile: MinefieldTile) -> Color {
        switch tile.state {
        case .hidden:
            return MinefieldTheme.panelStrong
        case .flagged:
            return MinefieldTheme.gold
        case .revealed:
            if tile.hasMine {
                return tile.isTriggeredMine ? MinefieldTheme.warning : MinefieldTheme.accent
            }
            return Color(red: 0.11, green: 0.15, blue: 0.19)
        }
    }

    private func tileBorder(for tile: MinefieldTile) -> Color {
        switch tile.state {
        case .hidden:
            return MinefieldTheme.border
        case .flagged:
            return MinefieldTheme.gold.opacity(0.35)
        case .revealed:
            if tile.hasMine {
                return tile.isTriggeredMine ? MinefieldTheme.warning.opacity(0.45) : MinefieldTheme.accent.opacity(0.38)
            }
            return Color.white.opacity(0.05)
        }
    }

    private func tileAccessibilityLabel(_ tile: MinefieldTile) -> String {
        switch tile.state {
        case .hidden:
            return "Hidden tile"
        case .flagged:
            return "Flagged tile"
        case .revealed:
            if tile.hasMine {
                return tile.isTriggeredMine ? "Triggered mine" : "Mine"
            }
            if tile.adjacentMineCount == 0 {
                return "Empty tile"
            }
            return "\(tile.adjacentMineCount) nearby mines"
        }
    }

    private func timeString(from value: TimeInterval) -> String {
        let totalSeconds = Int(value.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accent)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MinefieldTheme.textSecondary)
            }

            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MinefieldTheme.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MinefieldTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MinefieldTheme.border, lineWidth: 1)
        )
    }
}

private struct FooterPill: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .foregroundStyle(MinefieldTheme.textSecondary)
            Text(value)
                .foregroundStyle(MinefieldTheme.textPrimary)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(MinefieldTheme.panel, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(MinefieldTheme.border, lineWidth: 1)
        )
    }
}
