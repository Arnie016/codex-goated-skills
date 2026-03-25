import Foundation

actor PhoneSpotterSettingsStore {
    private let stateURL: URL

    init(fileManager: FileManager = .default) {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = appSupport.appendingPathComponent("PhoneSpotter", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        self.stateURL = directory.appendingPathComponent("state.json")
    }

    func load() -> PhoneSpotterState {
        guard
            let data = try? Data(contentsOf: stateURL),
            let state = try? JSONDecoder.phoneSpotter.decode(PhoneSpotterState.self, from: data)
        else {
            return .init()
        }

        return state
    }

    func save(_ state: PhoneSpotterState) {
        guard let data = try? JSONEncoder.phoneSpotter.encode(state) else { return }
        try? data.write(to: stateURL, options: [.atomic])
    }
}

private extension JSONEncoder {
    static var phoneSpotter: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var phoneSpotter: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
