import AppKit
import CoreAudio
import VibeWidgetCore

struct AudioRouteService {
    func currentStatus(preferredOutput: String) -> AudioRouteStatus {
        let current = currentOutputName() ?? "Mac Speakers"
        let outputs = availableOutputs()
        let availability: AudioRouteAvailability
        if current.localizedCaseInsensitiveContains(preferredOutput) {
            availability = .connected
        } else if outputs.contains(where: { $0.localizedCaseInsensitiveContains(preferredOutput) }) {
            availability = .available
        } else {
            availability = .missing
        }

        return AudioRouteStatus(
            preferredOutput: preferredOutput,
            currentOutput: current,
            availability: availability
        )
    }

    func availableOutputs() -> [String] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize) == noErr else {
            return []
        }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(bitPattern: 0), count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceIDs) == noErr else {
            return []
        }

        return deviceIDs.compactMap(deviceName)
            .filter { !$0.isEmpty }
            .sorted()
    }

    func openSoundSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound") else { return }
        NSWorkspace.shared.open(url)
    }

    func openBluetoothSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") else { return }
        NSWorkspace.shared.open(url)
    }

    private func currentOutputName() -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID = AudioDeviceID()
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceID) == noErr else {
            return nil
        }

        return deviceName(deviceID)
    }

    private func deviceName(_ id: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfName: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        guard AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &size, &cfName) == noErr else {
            return nil
        }
        return cfName as String
    }
}
