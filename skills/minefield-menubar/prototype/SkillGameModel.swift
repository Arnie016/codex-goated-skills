import Foundation
import SwiftUI

enum MinefieldInteractionMode: String, CaseIterable, Identifiable {
    case reveal = "Reveal"
    case flag = "Flag"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .reveal:
            return "sparkle.magnifyingglass"
        case .flag:
            return "flag.fill"
        }
    }
}

enum MinefieldOutcome: Equatable {
    case ready
    case inProgress
    case won
    case lost(triggeredIndex: Int)

    var isFinished: Bool {
        switch self {
        case .won, .lost:
            return true
        case .ready, .inProgress:
            return false
        }
    }
}

struct MinefieldTile: Identifiable {
    enum TileState {
        case hidden
        case flagged
        case revealed
    }

    let id: Int
    let row: Int
    let column: Int
    var hasMine = false
    var adjacentMineCount = 0
    var state: TileState = .hidden
    var isTriggeredMine = false

    init(id: Int, columns: Int) {
        self.id = id
        row = id / columns
        column = id % columns
    }
}

@MainActor
final class MinefieldGame: ObservableObject {
    static let rows = 8
    static let columns = 8
    static let mineCount = 10

    @Published private(set) var tiles: [MinefieldTile] = []
    @Published private(set) var outcome: MinefieldOutcome = .ready
    @Published private(set) var startedAt: Date?
    @Published private(set) var finishedAt: Date?
    @Published private(set) var revealCount = 0
    @Published private(set) var moveCount = 0
    @Published var mode: MinefieldInteractionMode = .reveal

    init() {
        reset()
    }

    var flaggedCount: Int {
        tiles.reduce(into: 0) { partialResult, tile in
            if tile.state == .flagged {
                partialResult += 1
            }
        }
    }

    var remainingMineEstimate: Int {
        max(Self.mineCount - flaggedCount, 0)
    }

    var safeTilesRemaining: Int {
        max((Self.rows * Self.columns - Self.mineCount) - revealCount, 0)
    }

    var isSeeded: Bool {
        tiles.contains(where: \.hasMine)
    }

    func reset() {
        tiles = (0..<(Self.rows * Self.columns)).map { MinefieldTile(id: $0, columns: Self.columns) }
        outcome = .ready
        startedAt = nil
        finishedAt = nil
        revealCount = 0
        moveCount = 0
        mode = .reveal
    }

    func handleSelection(for tileID: Int) {
        guard tiles.indices.contains(tileID), !outcome.isFinished else {
            return
        }

        switch mode {
        case .reveal:
            reveal(tileID)
        case .flag:
            toggleFlag(tileID)
        }
    }

    func elapsedTime(at date: Date = .now) -> TimeInterval {
        guard let startedAt else {
            return 0
        }

        let endDate = finishedAt ?? date
        return max(0, endDate.timeIntervalSince(startedAt))
    }

    private func reveal(_ tileID: Int) {
        let tile = tiles[tileID]

        guard tile.state == .hidden else {
            return
        }

        if !isSeeded {
            seedBoard(safeIndex: tileID)
            startedAt = Date()
            outcome = .inProgress
        }

        moveCount += 1

        if tiles[tileID].hasMine {
            triggerLoss(at: tileID)
            return
        }

        floodReveal(from: tileID)

        if safeTilesRemaining == 0 {
            registerWin()
        } else if outcome == .ready {
            outcome = .inProgress
        }
    }

    private func toggleFlag(_ tileID: Int) {
        guard tiles[tileID].state != .revealed else {
            return
        }

        switch tiles[tileID].state {
        case .hidden:
            tiles[tileID].state = .flagged
            moveCount += 1
        case .flagged:
            tiles[tileID].state = .hidden
            moveCount += 1
        case .revealed:
            break
        }
    }

    private func seedBoard(safeIndex: Int) {
        let protectedTiles = Set([safeIndex] + neighboringIndices(for: safeIndex))
        var available = tiles.indices.filter { !protectedTiles.contains($0) }
        available.shuffle()

        for mineIndex in available.prefix(Self.mineCount) {
            tiles[mineIndex].hasMine = true
        }

        for index in tiles.indices {
            tiles[index].adjacentMineCount = neighboringIndices(for: index)
                .reduce(into: 0) { partialResult, neighbor in
                    if tiles[neighbor].hasMine {
                        partialResult += 1
                    }
                }
        }
    }

    private func floodReveal(from startIndex: Int) {
        var queue = [startIndex]
        var visited = Set<Int>()

        while let current = queue.popLast() {
            guard !visited.contains(current) else {
                continue
            }

            visited.insert(current)

            guard tiles[current].state != .revealed, tiles[current].state != .flagged else {
                continue
            }

            guard !tiles[current].hasMine else {
                continue
            }

            tiles[current].state = .revealed
            revealCount += 1

            if tiles[current].adjacentMineCount == 0 {
                queue.append(contentsOf: neighboringIndices(for: current))
            }
        }
    }

    private func triggerLoss(at tileID: Int) {
        tiles[tileID].isTriggeredMine = true

        for index in tiles.indices where tiles[index].hasMine {
            tiles[index].state = .revealed
        }

        finishedAt = Date()
        outcome = .lost(triggeredIndex: tileID)
    }

    private func registerWin() {
        for index in tiles.indices where tiles[index].hasMine {
            tiles[index].state = .flagged
        }

        finishedAt = Date()
        outcome = .won
    }

    private func neighboringIndices(for index: Int) -> [Int] {
        let row = index / Self.columns
        let column = index % Self.columns
        var neighbors: [Int] = []

        for rowOffset in -1...1 {
            for columnOffset in -1...1 {
                guard !(rowOffset == 0 && columnOffset == 0) else {
                    continue
                }

                let nextRow = row + rowOffset
                let nextColumn = column + columnOffset

                guard nextRow >= 0, nextRow < Self.rows, nextColumn >= 0, nextColumn < Self.columns else {
                    continue
                }

                neighbors.append(nextRow * Self.columns + nextColumn)
            }
        }

        return neighbors
    }
}
