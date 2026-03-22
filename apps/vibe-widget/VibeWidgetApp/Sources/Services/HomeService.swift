import Foundation
import VibeWidgetCore

#if canImport(HomeKit)
import HomeKit

@MainActor
final class HomeService: NSObject, HMHomeManagerDelegate {
    private let manager = HMHomeManager()
    private var homesContinuation: CheckedContinuation<[HMHome], Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func fetchHomes() async -> [HomeSummary] {
        let homes = await resolvedHomes()
        return homes.map {
            HomeSummary(
                id: $0.uniqueIdentifier.uuidString,
                name: $0.name,
                rooms: $0.rooms.map { RoomSummary(id: $0.uniqueIdentifier.uuidString, name: $0.name) }.sorted { $0.name < $1.name },
                scenes: $0.actionSets.map { SceneSummary(id: $0.uniqueIdentifier.uuidString, name: $0.name) }.sorted { $0.name < $1.name }
            )
        }
    }

    func apply(light: LightCommand, roomName: String, settings: AppSettings) async -> String {
        guard light.action != .none else { return "Lights unchanged." }
        let homes = await resolvedHomes()
        guard let home = selectHome(from: homes, settings: settings) else {
            return "No Apple Home available yet."
        }

        if let scene = matchingScene(in: home, light: light, roomName: roomName) {
            do {
                try await execute(scene, in: home)
                return "Scene \(scene.name) is on."
            } catch {
                return "I found the scene, but Home couldn't run it."
            }
        }

        guard let room = home.rooms.first(where: { $0.name.localizedCaseInsensitiveCompare(roomName) == .orderedSame }) else {
            return "I couldn't find the \(roomName) room in Apple Home."
        }

        let lightbulbs = room.accessories
            .flatMap(\.services)
            .filter { $0.serviceType == HMServiceTypeLightbulb }

        guard !lightbulbs.isEmpty else {
            return "The \(roomName) room has no dimmable lights yet."
        }

        do {
            for service in lightbulbs {
                try await apply(light: light, to: service)
            }
            switch light.action {
            case .dim:
                return "\(roomName) lights dimmed."
            case .off:
                return "\(roomName) lights off."
            case .on:
                return "\(roomName) lights on."
            case .scene:
                return "Scene request sent."
            case .none:
                return "Lights unchanged."
            }
        } catch {
            return "HomeKit rejected the light update."
        }
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        homesContinuation?.resume(returning: manager.homes)
        homesContinuation = nil
    }

    private func resolvedHomes() async -> [HMHome] {
        if !manager.homes.isEmpty {
            return manager.homes
        }

        return await withCheckedContinuation { continuation in
            homesContinuation = continuation
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if let continuation = self.homesContinuation {
                    continuation.resume(returning: self.manager.homes)
                    self.homesContinuation = nil
                }
            }
        }
    }

    private func selectHome(from homes: [HMHome], settings: AppSettings) -> HMHome? {
        if let selectedHomeID = settings.selectedHomeID,
           let match = homes.first(where: { $0.uniqueIdentifier.uuidString == selectedHomeID }) {
            return match
        }
        return homes.first(where: { $0.name == settings.selectedHomeName }) ?? homes.first
    }

    private func matchingScene(in home: HMHome, light: LightCommand, roomName: String) -> HMActionSet? {
        if light.action == .scene, let sceneName = light.sceneName, !sceneName.isEmpty {
            return home.actionSets.first(where: { $0.name.localizedCaseInsensitiveCompare(sceneName) == .orderedSame })
        }

        let roomToken = roomName.lowercased()
        let candidates: [String]
        switch light.action {
        case .dim:
            candidates = ["\(roomToken) dim", "dim \(roomToken)", "night \(roomToken)"]
        case .off:
            candidates = ["\(roomToken) off", "lights out \(roomToken)"]
        case .on:
            candidates = ["\(roomToken) on", "\(roomToken) bright"]
        case .scene, .none:
            candidates = []
        }

        return home.actionSets.first { actionSet in
            let lowered = actionSet.name.lowercased()
            return candidates.contains(where: lowered.contains)
        }
    }

    private func execute(_ scene: HMActionSet, in home: HMHome) async throws {
        try await withCheckedThrowingContinuation { continuation in
            home.executeActionSet(scene) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func apply(light: LightCommand, to service: HMService) async throws {
        if let power = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
            switch light.action {
            case .dim, .on, .scene:
                try await write(true, to: power)
            case .off:
                try await write(false, to: power)
            case .none:
                break
            }
        }

        if light.action == .dim,
           let brightness = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
            try await write(light.brightnessPercent ?? 30, to: brightness)
        }
    }

    private func write(_ value: Any, to characteristic: HMCharacteristic) async throws {
        try await withCheckedThrowingContinuation { continuation in
            characteristic.writeValue(value) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

#else

@MainActor
final class HomeService {
    func fetchHomes() async -> [HomeSummary] { [] }

    func apply(light: LightCommand, roomName: String, settings: AppSettings) async -> String {
        "HomeKit needs the full Xcode SDK to run on this machine."
    }
}

#endif
