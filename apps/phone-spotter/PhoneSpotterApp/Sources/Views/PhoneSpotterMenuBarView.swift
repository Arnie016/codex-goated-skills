import SwiftUI

struct PhoneSpotterMenuBarView: View {
    @ObservedObject var model: PhoneSpotterAppModel

    var body: some View {
        ZStack {
            PhoneSpotterBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    headerCard
                    if model.needsSetup {
                        setupCard
                    }
                    actionGridCard
                    recoveryCard
                    contextCard
                    memoryCard
                    timelineCard
                    footerCard
                }
                .padding(10)
                .frame(width: 392)
            }
            .scrollIndicators(.hidden)
        }
        .controlSize(.small)
        .font(.system(size: 12))
    }

    private var headerCard: some View {
        PhoneSpotterCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.24, green: 0.58, blue: 0.98), Color(red: 0.2, green: 0.78, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay {
                            Image(systemName: model.platform.symbolName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Phone Spotter")
                                .font(.system(size: 15, weight: .semibold))
                            PhoneSpotterStatusPill(title: model.platform.title, tint: .blue)
                        }

                        Text(model.panelTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.97))

                        Text(model.panelSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 6) {
                    PhoneSpotterStatusPill(title: model.providerTitle, tint: .mint)
                    PhoneSpotterStatusPill(title: model.integrationMode.title, tint: .orange)
                    if model.hasCoordinates {
                        PhoneSpotterStatusPill(title: "Directions Ready", tint: .cyan)
                    }
                    if model.needsSetup {
                        PhoneSpotterStatusPill(title: "Pair Phone", tint: .pink)
                    }
                }

                HStack(alignment: .top, spacing: 8) {
                    PhoneSpotterMetricTile(
                        title: "Connection",
                        value: model.pairingHeadline,
                        symbolName: model.isPairingActive ? "qrcode.viewfinder" : "bolt.shield"
                    )
                    PhoneSpotterMetricTile(
                        title: "Number",
                        value: model.phoneNumberSummary,
                        symbolName: "phone.fill"
                    )
                    PhoneSpotterMetricTile(
                        title: "Locate",
                        value: model.hasCoordinates ? model.coordinatesSummary : "Provider ready",
                        symbolName: "location.fill"
                    )
                }

                Text(model.pairingDetail)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)

                if model.needsSetup {
                    HStack(spacing: 8) {
                        Button("Pair Phone Now") { model.startPairingSession() }
                            .buttonStyle(PhoneSpotterPrimaryButtonStyle())
                        Button("Open Pairing Page") { model.startPairingAndOpenPage() }
                            .buttonStyle(PhoneSpotterSecondaryButtonStyle())
                    }
                }

                if let message = model.feedbackMessage {
                    messageBanner(message: message, tint: .green, symbolName: "checkmark.circle.fill")
                } else if let message = model.errorMessage {
                    messageBanner(message: message, tint: .orange, symbolName: "exclamationmark.triangle.fill")
                }
            }
        }
    }

    private var actionGridCard: some View {
        PhoneSpotterCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick Actions")
                    .font(.system(size: 13, weight: .semibold))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    Button("Locate") { model.locatePhone() }
                        .buttonStyle(PhoneSpotterPrimaryButtonStyle())
                    Button("Ring") { model.ringPhone() }
                        .buttonStyle(PhoneSpotterPrimaryButtonStyle())
                    Button("Call") { model.callPhone() }
                        .buttonStyle(PhoneSpotterSecondaryButtonStyle())
                    Button("Directions") { model.openDirections() }
                        .buttonStyle(PhoneSpotterSecondaryButtonStyle())
                    Button("Open Provider") { model.openProviderPortal() }
                        .buttonStyle(PhoneSpotterSecondaryButtonStyle())
                    Button("Copy Summary") { model.copySummary() }
                        .buttonStyle(PhoneSpotterSecondaryButtonStyle())
                }

                if model.needsSetup {
                    Text("Finish setup below so Call and provider actions know which phone to use.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var setupCard: some View {
        PhoneSpotterCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Quick Setup")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer(minLength: 0)
                    PhoneSpotterStatusPill(title: "Required", tint: .orange)
                }

                Text("Connect your phone to this Mac once, then use the panel as the conductor for call, locate, ring, and memory.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                TextField("Phone name", text: $model.deviceName)
                    .textFieldStyle(.roundedBorder)

                Picker("Platform", selection: $model.platform) {
                    ForEach(PhonePlatform.allCases) { platform in
                        Text(platform.title).tag(platform)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Integration", selection: $model.integrationMode) {
                    ForEach(IntegrationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                TextField("Phone number", text: $model.phoneNumber)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    Button("Save Setup") { model.completeSetup() }
                        .buttonStyle(PhoneSpotterPrimaryButtonStyle())
                    Button("Open Settings") { model.openSettings() }
                        .buttonStyle(PhoneSpotterSecondaryButtonStyle())
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Pair With QR")
                            .font(.system(size: 12, weight: .semibold))
                        Spacer(minLength: 0)
                        if model.isPairingActive {
                            PhoneSpotterStatusPill(title: "Live", tint: .green)
                        }
                    }

                    Text(model.pairingStatus)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .center, spacing: 12) {
                        PhoneSpotterQRFrame(image: model.pairingQRCodeImage())

                        VStack(alignment: .leading, spacing: 8) {
                            Text(model.pairingURLString.isEmpty ? "Start a pairing session to generate a QR code your phone can scan on the same Wi-Fi." : model.pairingURLString)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.9))
                                .textSelection(.enabled)
                                .lineLimit(4)

                            Button(model.isPairingActive ? "Restart Pairing" : "Start Pairing QR") {
                                model.startPairingSession()
                            }
                            .buttonStyle(PhoneSpotterPrimaryButtonStyle())

                            if model.isPairingActive {
                                Button("Open Pair Page") {
                                    model.openPairingLink()
                                }
                                .buttonStyle(PhoneSpotterSecondaryButtonStyle())

                                Button("Copy Pair Link") {
                                    model.copyPairingLink()
                                }
                                .buttonStyle(PhoneSpotterSecondaryButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }

    private var contextCard: some View {
        PhoneSpotterCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Phone Card")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer(minLength: 0)
                    Text(model.confidenceTitle)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text(model.confidenceDetail)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)

                HStack(alignment: .top, spacing: 8) {
                    PhoneSpotterMetricTile(title: "Last Seen", value: model.lastSeenSummary, symbolName: "mappin.and.ellipse")
                    PhoneSpotterMetricTile(title: "Access", value: model.integrationMode.title, symbolName: "lock.shield")
                }

                HStack(alignment: .top, spacing: 8) {
                    PhoneSpotterMetricTile(title: "Coordinates", value: model.coordinatesSummary, symbolName: "location")
                    PhoneSpotterMetricTile(title: "IP Address", value: model.ipAddress.isEmpty ? "Needs companion" : model.ipAddress, symbolName: "network")
                }

                if !model.savedPlaces.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saved Places")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.42))
                        FlowLayout(model.savedPlaces, spacing: 8, lineSpacing: 8) { place in
                            PhoneSpotterChipButton(title: place) {
                                model.useSavedPlace(place)
                            }
                        }
                    }
                }
            }
        }
    }

    private var memoryCard: some View {
        PhoneSpotterCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Remember")
                    .font(.system(size: 13, weight: .semibold))

                TextEditor(text: $model.quickRememberNote)
                    .font(.system(size: 11.5))
                    .scrollContentBackground(.hidden)
                    .frame(height: 70)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )

                HStack(spacing: 8) {
                    Button("Save Memory") { model.rememberNow() }
                        .buttonStyle(PhoneSpotterPrimaryButtonStyle())
                    Button("Settings") { model.openSettings() }
                        .buttonStyle(PhoneSpotterSecondaryButtonStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Clues")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.42))
                    FlowLayout(model.quickClueSuggestions, spacing: 8, lineSpacing: 8) { clue in
                        PhoneSpotterChipButton(title: clue) {
                            model.applyQuickClue(clue)
                        }
                    }
                }

                if !model.pinnedClues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pinned Clues")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.42))
                        FlowLayout(model.pinnedClues, spacing: 8, lineSpacing: 8) { clue in
                            PhoneSpotterChipButton(title: clue) {
                                model.applyQuickClue(clue)
                            }
                        }
                    }
                }

                Text(model.lastUsedSummary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var recoveryCard: some View {
        PhoneSpotterCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recovery Flow")
                    .font(.system(size: 13, weight: .semibold))

                HStack(alignment: .top, spacing: 8) {
                    recoveryStep(title: "1. Ring", detail: "Trigger sound through your trusted provider.")
                    recoveryStep(title: "2. Provider", detail: "Open Apple or Google for live locate tools.")
                    recoveryStep(title: "3. Remember", detail: "Save the clue you just noticed before it fades.")
                }
            }
        }
    }

    private var timelineCard: some View {
        PhoneSpotterCard {
            VStack(alignment: .leading, spacing: 9) {
                Text("Last Seen Timeline")
                    .font(.system(size: 13, weight: .semibold))

                if model.timeline.isEmpty {
                    Text("Actions you take from the menu bar will show up here.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.timeline.prefix(4)) { entry in
                        HStack(alignment: .top, spacing: 9) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Image(systemName: symbolName(for: entry.kind))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.white.opacity(0.82))
                                }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(entry.title)
                                        .font(.system(size: 11.5, weight: .semibold))
                                        .foregroundStyle(Color.white.opacity(0.95))
                                    Spacer(minLength: 0)
                                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }

                                Text(entry.detail)
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
    }

    private var footerCard: some View {
        PhoneSpotterCard {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Phone Spotter")
                        .font(.system(size: 11, weight: .semibold))
                    Text(model.hasCoordinates ? model.coordinatesSummary : "Provider tools ready")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button("Quit") { model.quitApp() }
                    .buttonStyle(PhoneSpotterSecondaryButtonStyle())
                Button("Open Provider") { model.openProviderPortal() }
                    .buttonStyle(PhoneSpotterPrimaryButtonStyle())
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.42))
            Text(value)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func messageBanner(message: String, tint: Color, symbolName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
            Text(message)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func recoveryStep(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.96))
            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func symbolName(for kind: PhoneActionKind) -> String {
        switch kind {
        case .locate:
            return "location.fill"
        case .ring:
            return "bell.fill"
        case .call:
            return "phone.fill"
        case .directions:
            return "arrow.triangle.turn.up.right.diamond.fill"
        case .openProvider:
            return "safari.fill"
        case .remember:
            return "brain.head.profile"
        case .copySummary:
            return "doc.on.doc.fill"
        }
    }
}

private struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: (Data.Element) -> Content

    init(_ data: Data, spacing: CGFloat, lineSpacing: CGFloat, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: spacing, alignment: .leading)], alignment: .leading, spacing: lineSpacing) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
            }
        }
    }
}

struct PhoneSpotterSettingsView: View {
    @ObservedObject var model: PhoneSpotterAppModel

    var body: some View {
        Form {
            Section("Phone Profile") {
                TextField("Device name", text: $model.deviceName)

                Picker("Platform", selection: $model.platform) {
                    ForEach(PhonePlatform.allCases) { platform in
                        Text(platform.title).tag(platform)
                    }
                }

                Picker("Integration", selection: $model.integrationMode) {
                    ForEach(IntegrationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                TextField("Phone number", text: $model.phoneNumber)
            }

            Section("Locate Context") {
                TextField("Last seen place", text: $model.lastSeenLabel)
                TextField("Latitude", text: $model.latitudeText)
                TextField("Longitude", text: $model.longitudeText)
                TextField("IP address", text: $model.ipAddress)
            }

            Section("Remember Last Use") {
                TextField("Last activity note", text: $model.lastUsedNote, axis: .vertical)
                Toggle("Allow ring actions", isOn: $model.allowRing)
                Toggle("Allow call actions", isOn: $model.allowCall)
                Toggle("Allow manual notes", isOn: $model.allowManualNotes)
            }

            Section("Notes") {
                Text("Native app and web portal actions open the trusted Apple or Google surface as fast as possible. IP address, richer activity history, or background telemetry need extra permissions or a future companion connection.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }
}
