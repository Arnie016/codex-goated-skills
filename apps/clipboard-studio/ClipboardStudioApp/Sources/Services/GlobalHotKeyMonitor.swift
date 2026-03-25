import Carbon
import Foundation

final class GlobalHotKeyMonitor {
    enum ShortcutAction: UInt32 {
        case captureSelection = 1
        case sendPack = 2
        case openPack = 3
    }

    private struct Registration {
        let reference: EventHotKeyRef?
        let handler: () -> Void
    }

    private static let signature = OSType(0x43505354) // "CPST"

    private var registrations: [UInt32: Registration] = [:]
    private var eventHandler: EventHandlerRef?

    init() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            Self.hotKeyHandler,
            1,
            &eventSpec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )
    }

    deinit {
        for registration in registrations.values {
            if let reference = registration.reference {
                UnregisterEventHotKey(reference)
            }
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    @discardableResult
    func register(
        action: ShortcutAction,
        keyCode: UInt32,
        modifiers: UInt32,
        handler: @escaping () -> Void
    ) -> Bool {
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: action.rawValue)
        var reference: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &reference
        )

        guard status == noErr else {
            return false
        }

        registrations[action.rawValue] = Registration(reference: reference, handler: handler)
        return true
    }

    private func handleHotKey(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr,
              hotKeyID.signature == Self.signature,
              let registration = registrations[hotKeyID.id] else {
            return noErr
        }

        registration.handler()
        return noErr
    }

    private static let hotKeyHandler: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else { return noErr }
        let monitor = Unmanaged<GlobalHotKeyMonitor>.fromOpaque(userData).takeUnretainedValue()
        return monitor.handleHotKey(event)
    }
}
