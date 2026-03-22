import AVFoundation
import Speech
import VibeWidgetCore

@MainActor
final class PermissionService {
    func refresh(homeAvailable: Bool) async -> PermissionSnapshot {
        PermissionSnapshot(
            microphone: microphoneStatus(),
            speech: speechStatus(),
            home: homeAvailable ? .granted : .unknown,
            automation: .unknown
        )
    }

    func requestMicrophone() async -> PermissionSnapshot.State {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { continuation.resume(returning: $0) }
            }
            return granted ? .granted : .denied
        @unknown default:
            return .unknown
        }
    }

    func requestSpeech() async -> PermissionSnapshot.State {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized {
            return .granted
        }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authorization in
                let state: PermissionSnapshot.State
                switch authorization {
                case .authorized:
                    state = .granted
                case .denied, .restricted:
                    state = .denied
                case .notDetermined:
                    state = .unknown
                @unknown default:
                    state = .unknown
                }
                continuation.resume(returning: state)
            }
        }
    }

    private func microphoneStatus() -> PermissionSnapshot.State {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    private func speechStatus() -> PermissionSnapshot.State {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
