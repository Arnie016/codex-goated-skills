import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

@MainActor
final class PhoneSpotterAppModel: ObservableObject {
    static let shared = PhoneSpotterAppModel()

    @Published var hasCompletedSetup = false { didSet { persistIfReady() } }
    @Published var deviceName = "My Phone" { didSet { persistIfReady() } }
    @Published var platform: PhonePlatform = .iphone { didSet { normalizePlatformDefaults(); persistIfReady() } }
    @Published var integrationMode: IntegrationMode = .nativeApp { didSet { persistIfReady() } }
    @Published var phoneNumber = "" { didSet { persistIfReady() } }
    @Published var allowRing = true { didSet { persistIfReady() } }
    @Published var allowCall = true { didSet { persistIfReady() } }
    @Published var allowManualNotes = true { didSet { persistIfReady() } }

    @Published var lastSeenLabel = "No provider location captured yet." { didSet { persistIfReady() } }
    @Published var latitudeText = "" { didSet { persistIfReady() } }
    @Published var longitudeText = "" { didSet { persistIfReady() } }
    @Published var ipAddress = "" { didSet { persistIfReady() } }
    @Published var lastUsedNote = "Add the last thing you remember doing with your phone." { didSet { persistIfReady() } }
    @Published var lastUsedAt: Date? { didSet { persistIfReady() } }
    @Published var providerStatus = "Waiting for your preferred provider flow." { didSet { persistIfReady() } }
    @Published var pinnedClues: [String] = [] { didSet { persistIfReady() } }
    @Published var savedPlaces: [String] = ["Home", "Office", "Car", "Gym"] { didSet { persistIfReady() } }
    @Published var quickRememberNote = ""
    @Published var pairingCode = ""
    @Published var pairingURLString = ""
    @Published var pairingStatus = "Not paired yet."

    @Published var feedbackMessage: String?
    @Published var errorMessage: String?
    @Published var timeline: [PhoneSpotterLogEntry] = []

    private let store = PhoneSpotterSettingsStore()
    private let qrContext = CIContext()
    private var isHydrating = true
    private var clearMessageTask: Task<Void, Never>?
    private var pairingServer: PhoneSpotterPairingServer?

    private init() {
        Task {
            let state = await store.load()
            await MainActor.run {
                apply(state)
                isHydrating = false
                if timeline.isEmpty {
                    appendLog(
                        title: "Ready",
                        detail: "Choose your phone platform, then use Locate or Ring when you need it.",
                        kind: .remember,
                        persist: true
                    )
                }
            }
        }
    }

    deinit {
        clearMessageTask?.cancel()
    }

    var providerTitle: String { platform.providerTitle }

    var needsSetup: Bool {
        !hasCompletedSetup || sanitizedPhoneNumber.isEmpty || panelTitle == "My Phone"
    }

    var isPairingActive: Bool {
        pairingServer != nil && !pairingURLString.isEmpty
    }

    var panelTitle: String { deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Phone" : deviceName }

    var panelSubtitle: String {
        let status = providerStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        return status.isEmpty ? integrationMode.subtitle : status
    }

    var pairingHeadline: String {
        if isPairingActive {
            return "Ready to pair on this Wi-Fi"
        }
        if hasCompletedSetup {
            return "Connected to this Mac"
        }
        return "Needs a phone connection"
    }

    var pairingDetail: String {
        if isPairingActive {
            return "Scan the QR code with your phone to register it with this Mac."
        }
        if hasCompletedSetup {
            return "Saved for quick call, locate, ring, and provider handoff."
        }
        return "Use QR pairing or the quick setup fields below to teach Phone Spotter which phone to control."
    }

    var phoneNumberSummary: String {
        sanitizedPhoneNumber.isEmpty ? "Not saved" : sanitizedPhoneNumber
    }

    var confidenceTitle: String {
        if isPairingActive {
            return "Ready to pair"
        }
        if hasCoordinates {
            return "Location saved"
        }
        if !lastSeenSummary.lowercased().contains("no last-seen") {
            return "Clue available"
        }
        if hasCompletedSetup {
            return "Provider ready"
        }
        return "Needs setup"
    }

    var confidenceDetail: String {
        if isPairingActive {
            return "Your Mac is waiting for the phone to scan the QR code on the same Wi-Fi."
        }
        if hasCoordinates {
            return "You have coordinates saved, so directions and provider handoff are ready."
        }
        if !pinnedClues.isEmpty {
            return "Pinned clues can help you retrace the last known phone context quickly."
        }
        if hasCompletedSetup {
            return "The profile is saved. Use Ring, Locate, or Provider to continue the recovery flow."
        }
        return "Finish pairing or quick setup so this Mac knows which phone to help you find."
    }

    var quickClueSuggestions: [String] {
        ["On silent", "Charging", "In bag", "Left in car"]
    }

    var coordinatesSummary: String {
        guard let latitude, let longitude else { return "No coordinates saved" }
        return String(format: "%.5f, %.5f", latitude, longitude)
    }

    var latitude: Double? { Double(latitudeText.trimmingCharacters(in: .whitespacesAndNewlines)) }
    var longitude: Double? { Double(longitudeText.trimmingCharacters(in: .whitespacesAndNewlines)) }

    var menuBarSymbolName: String {
        if errorMessage != nil {
            return "exclamationmark.circle.fill"
        }
        if hasCoordinates {
            return "location.fill"
        }
        return platform == .iphone ? "dot.radiowaves.left.and.right" : "location.magnifyingglass"
    }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    var lastSeenSummary: String {
        let trimmed = lastSeenLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No last-seen note yet." : trimmed
    }

    var lastUsedSummary: String {
        let trimmed = lastUsedNote.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No recent memory note yet." : trimmed
    }

    func locatePhone() {
        providerStatus = "Opening \(providerTitle) locate flow..."
        appendLog(title: "Locate Requested", detail: "Opened the fastest available \(providerTitle) surface.", kind: .locate)
        openProvider(for: .locate)
        setFeedback("Locate flow opened in \(providerTitle).")
    }

    func ringPhone() {
        guard allowRing else {
            setError("Ring is disabled for this phone profile.")
            return
        }
        providerStatus = "Opening the ring flow in \(providerTitle)..."
        appendLog(title: "Ring Requested", detail: "Sent you to the provider flow to play a sound on the phone.", kind: .ring)
        openProvider(for: .ring)
        setFeedback("Ring flow opened. Finish the sound action in \(providerTitle).")
    }

    func callPhone() {
        guard allowCall else {
            setError("Calling is disabled for this phone profile.")
            return
        }

        let digits = sanitizedPhoneNumber
        guard !digits.isEmpty else {
            setError("Add a phone number first so the Mac can place the call.")
            return
        }

        let candidates = [
            "facetime-audio://\(digits)",
            "tel://\(digits)"
        ].compactMap(URL.init(string:))

        if let openedURL = candidates.first(where: { NSWorkspace.shared.open($0) }) {
            appendLog(title: "Call Started", detail: "Opened \(openedURL.scheme ?? "call") for \(digits).", kind: .call)
            setFeedback("Calling \(digits) from the Mac.")
        } else {
            setError("The Mac could not open a calling app for \(digits). Check FaceTime or Phone settings.")
        }
    }

    func openDirections() {
        if let latitude, let longitude {
            let name = panelTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Phone"
            let urlString = "maps://?ll=\(latitude),\(longitude)&q=\(name)"
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
                appendLog(title: "Directions Opened", detail: "Opened Maps to the last saved coordinates.", kind: .directions)
                setFeedback("Directions opened in Maps.")
                return
            }
        }

        let query = lastSeenSummary.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Phone"
        if let url = URL(string: "maps://?q=\(query)") {
            NSWorkspace.shared.open(url)
            appendLog(title: "Map Search Opened", detail: "Opened Maps with your last-seen note.", kind: .directions)
            setFeedback("Opened Maps with your last-seen note.")
        }
    }

    func openProviderPortal() {
        openProvider(for: .openProvider)
        appendLog(title: "Provider Opened", detail: "Opened \(providerTitle) using \(integrationMode.title).", kind: .openProvider)
        setFeedback("\(providerTitle) opened.")
    }

    func rememberNow() {
        guard allowManualNotes else {
            setError("Manual notes are disabled for this phone profile.")
            return
        }

        let trimmed = quickRememberNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = trimmed.isEmpty ? "You marked this moment as the latest remembered activity." : trimmed
        lastUsedNote = note
        lastUsedAt = .now
        quickRememberNote = ""
        appendLog(title: "Memory Saved", detail: note, kind: .remember)
        setFeedback("Saved your latest phone memory.")
    }

    func applyQuickClue(_ clue: String) {
        lastUsedNote = clue
        lastUsedAt = .now
        updatePinnedCollection(with: clue)
        appendLog(title: "Clue Pinned", detail: clue, kind: .remember)
        setFeedback("Pinned clue saved.")
    }

    func useSavedPlace(_ place: String) {
        lastSeenLabel = place
        updateSavedPlaces(with: place)
        appendLog(title: "Saved Place", detail: "Marked \(place) as your current best last-seen clue.", kind: .directions)
        setFeedback("Saved \(place) as the current place clue.")
    }

    func copySummary() {
        let summary = """
        \(panelTitle)
        Platform: \(platform.title)
        Provider: \(providerTitle)
        Last seen: \(lastSeenSummary)
        Coordinates: \(coordinatesSummary)
        IP address: \(ipAddress.isEmpty ? "Not provided" : ipAddress)
        Last used: \(lastUsedSummary)
        Last used time: \(formatted(lastUsedAt))
        """

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(summary, forType: .string)
        appendLog(title: "Summary Copied", detail: "Copied the current phone summary to the clipboard.", kind: .copySummary)
        setFeedback("Phone summary copied.")
    }

    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func completeSetup() {
        let digits = sanitizedPhoneNumber
        guard !digits.isEmpty else {
            setError("Add your phone number first so Call can work.")
            return
        }

        if deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deviceName = platform == .iphone ? "My iPhone" : "My Android"
        }

        hasCompletedSetup = true
        providerStatus = "Ready for \(providerTitle) actions."
        appendLog(title: "Setup Finished", detail: "Saved your phone profile and quick actions.", kind: .remember)
        setFeedback("Phone setup saved.")
    }

    func startPairingSession() {
        let code = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)).uppercased()
        pairingCode = code
        pairingURLString = ""
        pairingStatus = "Starting a pairing link for your phone..."

        pairingServer?.stop()
        let server = PhoneSpotterPairingServer(pairingCode: code) { [weak self] event in
            Task { @MainActor in
                self?.handlePairingEvent(event)
            }
        }
        pairingServer = server
        server.start()
    }

    func copyPairingLink() {
        guard !pairingURLString.isEmpty else {
            setError("Start a pairing session first.")
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(pairingURLString, forType: .string)
        setFeedback("Pairing link copied.")
    }

    func openPairingLink() {
        guard let url = URL(string: pairingURLString), !pairingURLString.isEmpty else {
            setError("Start a pairing session first.")
            return
        }

        NSWorkspace.shared.open(url)
        setFeedback("Opened the pairing page on this Mac.")
    }

    func startPairingAndOpenPage() {
        startPairingSession()
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            self?.openPairingLink()
        }
    }

    func pairingQRCodeImage() -> NSImage? {
        guard !pairingURLString.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(pairingURLString.utf8), forKey: "inputMessage")
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = qrContext.createCGImage(transformed, from: transformed.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: transformed.extent.width, height: transformed.extent.height))
    }

    func quitApp() {
        pairingServer?.stop()
        NSApp.terminate(nil)
    }

    private func handlePairingEvent(_ event: PhoneSpotterPairingServer.Event) {
        switch event {
        case .ready(let url):
            pairingURLString = url
            pairingStatus = "Scan the QR code with your phone while both devices are on the same Wi-Fi."
            setFeedback("Pairing QR is ready.")
        case .paired(let payload):
            deviceName = payload.deviceName
            phoneNumber = payload.phoneNumber
            platform = payload.platform
            integrationMode = payload.integrationMode
            hasCompletedSetup = true
            pairingStatus = "\(payload.deviceName) paired with this Mac."
            providerStatus = "Paired and ready for \(providerTitle) actions."
            appendLog(title: "Phone Paired", detail: "\(payload.deviceName) registered through the QR pairing flow.", kind: .remember)
            setFeedback("\(payload.deviceName) paired successfully.")
            pairingServer?.stop()
            pairingServer = nil
        case .failed(let message):
            pairingStatus = message
            setError(message)
            pairingServer?.stop()
            pairingServer = nil
        }
    }

    private func openProvider(for action: PhoneActionKind) {
        switch platform {
        case .iphone:
            openAppleProvider(for: action)
        case .android:
            openGoogleProvider(for: action)
        }
    }

    private func openAppleProvider(for action: PhoneActionKind) {
        switch integrationMode {
        case .nativeApp:
            if let url = URL(string: "findmy://") {
                NSWorkspace.shared.open(url)
            } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.findmy") {
                NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
        case .webPortal, .guidedCompanion:
            if let url = URL(string: "https://www.icloud.com/find") {
                NSWorkspace.shared.open(url)
            }
        }

        if action == .ring {
            providerStatus = "Use Play Sound in Find My to ring the iPhone."
        }
    }

    private func openGoogleProvider(for action: PhoneActionKind) {
        if let url = URL(string: "https://android.com/find") {
            NSWorkspace.shared.open(url)
        }

        if action == .ring {
            providerStatus = "Use Play Sound in Google Find to ring the Android phone."
        }
    }

    private func normalizePlatformDefaults() {
        if platform == .android && integrationMode == .nativeApp {
            integrationMode = .webPortal
        }
        if platform == .iphone && integrationMode == .webPortal && providerStatus.contains("Google") {
            providerStatus = "Waiting for your preferred provider flow."
        }
    }

    private func apply(_ state: PhoneSpotterState) {
        hasCompletedSetup = state.profile.hasCompletedSetup
        deviceName = state.profile.deviceName
        platform = state.profile.platform
        integrationMode = state.profile.integrationMode
        phoneNumber = state.profile.phoneNumber
        allowRing = state.profile.allowRing
        allowCall = state.profile.allowCall
        allowManualNotes = state.profile.allowManualNotes

        lastSeenLabel = state.snapshot.lastSeenLabel
        latitudeText = state.snapshot.latitude.map { String($0) } ?? ""
        longitudeText = state.snapshot.longitude.map { String($0) } ?? ""
        ipAddress = state.snapshot.ipAddress
        lastUsedNote = state.snapshot.lastUsedNote
        lastUsedAt = state.snapshot.lastUsedAt
        providerStatus = state.snapshot.providerStatus
        pinnedClues = state.snapshot.pinnedClues
        savedPlaces = state.snapshot.savedPlaces.isEmpty ? ["Home", "Office", "Car", "Gym"] : state.snapshot.savedPlaces
        timeline = state.entries.sorted { $0.timestamp > $1.timestamp }
    }

    private func currentState() -> PhoneSpotterState {
        PhoneSpotterState(
            profile: PhoneSpotterProfile(
                hasCompletedSetup: hasCompletedSetup,
                deviceName: deviceName,
                platform: platform,
                integrationMode: integrationMode,
                phoneNumber: phoneNumber,
                allowRing: allowRing,
                allowCall: allowCall,
                allowManualNotes: allowManualNotes
            ),
            snapshot: PhoneSpotterSnapshot(
                lastSeenLabel: lastSeenLabel,
                latitude: latitude,
                longitude: longitude,
                ipAddress: ipAddress,
                lastUsedNote: lastUsedNote,
                lastUsedAt: lastUsedAt,
                providerStatus: providerStatus,
                pinnedClues: pinnedClues,
                savedPlaces: savedPlaces
            ),
            entries: timeline
        )
    }

    private func updatePinnedCollection(with clue: String) {
        let trimmed = clue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pinnedClues.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        pinnedClues.insert(trimmed, at: 0)
        if pinnedClues.count > 6 {
            pinnedClues = Array(pinnedClues.prefix(6))
        }
    }

    private func updateSavedPlaces(with place: String) {
        let trimmed = place.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        savedPlaces.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        savedPlaces.insert(trimmed, at: 0)
        if savedPlaces.count > 6 {
            savedPlaces = Array(savedPlaces.prefix(6))
        }
    }

    private func persistIfReady() {
        guard !isHydrating else { return }
        Task { await store.save(currentState()) }
    }

    private func appendLog(title: String, detail: String, kind: PhoneActionKind, persist: Bool = true) {
        timeline.insert(PhoneSpotterLogEntry(title: title, detail: detail, kind: kind), at: 0)
        if timeline.count > 16 {
            timeline = Array(timeline.prefix(16))
        }
        if persist {
            persistIfReady()
        }
    }

    private func setFeedback(_ message: String) {
        feedbackMessage = message
        errorMessage = nil
        scheduleMessageClear()
    }

    private func setError(_ message: String) {
        errorMessage = message
        feedbackMessage = nil
        scheduleMessageClear()
    }

    private func scheduleMessageClear() {
        clearMessageTask?.cancel()
        clearMessageTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.feedbackMessage = nil
                self?.errorMessage = nil
            }
        }
    }

    private var sanitizedPhoneNumber: String {
        var cleaned = ""
        for character in phoneNumber {
            if character.isNumber {
                cleaned.append(character)
            } else if character == "+", cleaned.isEmpty {
                cleaned.append(character)
            }
        }
        return cleaned
    }

    func formatted(_ date: Date?) -> String {
        guard let date else { return "Not set" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
