import SwiftUI

struct MinesweeperMenuBarView: View {
    @StateObject private var game = MinesweeperGame()
    @State private var showsNotes = false

    @AppStorage("minesweeper-menubar.best-time") private var bestTime = 0.0
    @AppStorage("minesweeper-menubar.win-streak") private var winStreak = 0
    @AppStorage("minesweeper-menubar.best-streak") private var bestStreak = 0

    private let sections = MinesweeperDetailView.previewSections
    private let columns = Array(repeating: GridItem(.fixed(32), spacing: 4), count: MinesweeperGame.columns)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statRow
            modeRow
            board
            footer
            notes
        }
        .padding(16)
        .frame(width: 360)
        .background(MinesweeperTheme.background)
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
                    Image(systemName: headerSymbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(headerColor)
                    Text(headerTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MinesweeperTheme.textPrimary)
                }

                Text(statusLine)
                    .font(.subheadline)
                    .foregroundStyle(MinesweeperTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                game.reset()
            } label: {
                Label("Reset", systemImage: "arrow.clockwise")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(MinesweeperTheme.accent)
        }
    }

    private var statRow: some View {
        HStack(spacing: 8) {
            MinesweeperStatCard(
                title: "Mines",
                value: "\(game.remainingMineEstimate)",
                systemImage: "flag.pattern.checkered",
                accent: MinesweeperTheme.warning
            )

            TimelineView(.periodic(from: .now, by: 1)) { context in
                MinesweeperStatCard(
                    title: "Time",
                    value: timeString(from: game.elapsedTime(at: context.date)),
                    systemImage: "timer",
                    accent: MinesweeperTheme.accent
                )
            }

            MinesweeperStatCard(
                title: "Best",
                value: bestTime == 0 ? "--:--" : timeString(from: bestTime),
                systemImage: "trophy.fill",
                accent: MinesweeperTheme.caution
            )
        }
    }

    private var modeRow: some View {
        HStack(spacing: 8) {
            ForEach(MinesweeperInteractionMode.allCases) { mode in
                Button {
                    game.mode = mode
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 12, weight: .bold))
                        Text(mode.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(game.mode == mode ? Color.black : MinesweeperTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(game.mode == mode ? MinesweeperTheme.accent : MinesweeperTheme.panel)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(game.mode == mode ? MinesweeperTheme.accentSoft.opacity(0.25) : MinesweeperTheme.border, lineWidth: 1)
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
                .fill(MinesweeperTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MinesweeperTheme.border, lineWidth: 1)
        )
    }

    private var footer: some View {
        HStack(spacing: 10) {
            FooterPill(title: "Moves", value: "\(game.moveCount)")
            FooterPill(title: "Streak", value: "\(winStreak)")
            FooterPill(title: "Best streak", value: "\(bestStreak)")
            Spacer(minLength: 0)
            Text("\(game.safeTilesRemaining) safe left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MinesweeperTheme.textSecondary)
        }
    }

    private var notes: some View {
        DisclosureGroup(isExpanded: $showsNotes) {
            MinesweeperDetailView(sections: sections)
                .padding(.top, 10)
        } label: {
            Text("Swift menu bar app notes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MinesweeperTheme.textPrimary)
        }
        .tint(MinesweeperTheme.accent)
    }

    private var headerTitle: String {
        switch game.outcome {
        case .ready:
            return "Minesweeper ready"
        case .inProgress:
            return "Board in play"
        case .won:
            return "Board cleared"
        case .lost:
            return "Mine hit"
        }
    }

    private var statusLine: String {
        switch game.outcome {
        case .ready:
            return "Click the icon, start the board, and use Flag mode when you want to mark a suspected mine."
        case .inProgress:
            return game.safeTilesRemaining == 1
                ? "One safe tile left."
                : "\(game.safeTilesRemaining) safe tiles remain."
        case .won:
            return "You cleared the popover board. Reset and go again."
        case .lost:
            return "The triggered mine is highlighted. Reset to restart."
        }
    }

    private var headerSymbol: String {
        switch game.outcome {
        case .ready:
            return "flag.pattern.checkered"
        case .inProgress:
            return game.mode == .reveal ? "hand.tap.fill" : "flag.fill"
        case .won:
            return "checkmark.seal.fill"
        case .lost:
            return "burst.fill"
        }
    }

    private var headerColor: Color {
        switch game.outcome {
        case .ready, .inProgress:
            return MinesweeperTheme.accent
        case .won:
            return MinesweeperTheme.caution
        case .lost:
            return MinesweeperTheme.warning
        }
    }

    @ViewBuilder
    private func tileFace(_ tile: MinesweeperTile) -> some View {
        switch tile.state {
        case .hidden:
            Image(systemName: "square.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(MinesweeperTheme.textSecondary.opacity(0.4))
        case .flagged:
            Image(systemName: "flag.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.88))
        case .revealed:
            if tile.hasMine {
                Image(systemName: tile.isTriggeredMine ? "burst.fill" : "circle.hexagongrid.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tile.isTriggeredMine ? Color.white : Color.black.opacity(0.88))
            } else if tile.adjacentMineCount > 0 {
                Text("\(tile.adjacentMineCount)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MinesweeperTheme.numberColor(tile.adjacentMineCount))
            } else {
                EmptyView()
            }
        }
    }

    private func tileBackground(for tile: MinesweeperTile) -> Color {
        switch tile.state {
        case .hidden:
            return MinesweeperTheme.panelStrong
        case .flagged:
            return MinesweeperTheme.caution
        case .revealed:
            if tile.hasMine {
                return tile.isTriggeredMine ? MinesweeperTheme.warning : MinesweeperTheme.accent
            }
            return Color(red: 0.11, green: 0.15, blue: 0.19)
        }
    }

    private func tileBorder(for tile: MinesweeperTile) -> Color {
        switch tile.state {
        case .hidden:
            return MinesweeperTheme.border
        case .flagged:
            return MinesweeperTheme.caution.opacity(0.35)
        case .revealed:
            if tile.hasMine {
                return tile.isTriggeredMine ? MinesweeperTheme.warning.opacity(0.45) : MinesweeperTheme.accent.opacity(0.38)
            }
            return Color.white.opacity(0.05)
        }
    }

    private func tileAccessibilityLabel(_ tile: MinesweeperTile) -> String {
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

private struct MinesweeperStatCard: View {
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
                    .foregroundStyle(MinesweeperTheme.textSecondary)
            }

            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MinesweeperTheme.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MinesweeperTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MinesweeperTheme.border, lineWidth: 1)
        )
    }
}

private struct FooterPill: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .foregroundStyle(MinesweeperTheme.textSecondary)
            Text(value)
                .foregroundStyle(MinesweeperTheme.textPrimary)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(MinesweeperTheme.panel, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(MinesweeperTheme.border, lineWidth: 1)
        )
    }
}
