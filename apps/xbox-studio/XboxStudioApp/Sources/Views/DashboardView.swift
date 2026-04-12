import SwiftUI
import UniformTypeIdentifiers

private enum XboxDashboardPalette {
    static let backgroundTop = Color(red: 0.94, green: 0.98, blue: 0.95)
    static let backgroundBottom = Color(red: 0.98, green: 0.99, blue: 0.97)
    static let card = Color.white
    static let border = Color.black.opacity(0.06)
    static let primary = Color(red: 0.10, green: 0.14, blue: 0.11)
    static let secondary = Color(red: 0.33, green: 0.39, blue: 0.35)
    static let accent = Color(red: 0.06, green: 0.49, blue: 0.12)
}

struct DashboardView: View {
    @ObservedObject var model: XboxStudioModel
    @State private var isDropTargeted = false
    @State private var showImporter = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    XboxDashboardPalette.backgroundTop,
                    model.controllers.primaryCard.level.color.opacity(0.14),
                    model.connectivity.level.color.opacity(0.08),
                    XboxDashboardPalette.backgroundBottom,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero
                    controllerSection
                    connectivitySection
                    capturesSection
                    boundarySection
                }
                .padding(28)
            }
        }
        .task {
            model.refresh()
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie, .png, .jpeg, .heic, .gif],
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            model.importCaptureFiles(from: urls)
        }
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Xbox Studio")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(XboxDashboardPalette.primary)

                Text("A controller-first macOS menu bar hub for Bluetooth readiness, Xbox controller pairing, cloud gaming, Remote Play launch, and a local capture inbox.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(XboxDashboardPalette.secondary)

                TextField("Optional player label or note", text: $model.playerLabel)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)

                HStack(spacing: 10) {
                    heroButton("Bluetooth Settings", systemImage: "dot.radiowaves.left.and.right") { model.openBluetoothSettings() }
                    heroButton("Apple Pairing Guide", systemImage: "book.closed") { model.openApplePairingGuide() }
                    heroButton("Cloud Gaming", systemImage: "cloud.fill") { model.openCloudGaming() }
                    heroButton("Remote Play", systemImage: "play.tv.fill") { model.openRemotePlay() }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                capsuleLabel(model.controllers.summaryTitle, color: model.controllers.primaryCard.level.color)
                capsuleLabel(model.connectivity.headline, color: model.connectivity.level.color)
                capsuleLabel("\(model.captures.count) captures in inbox", color: XboxDashboardPalette.accent)
                Button {
                    model.refresh()
                } label: {
                    Label("Refresh Checks", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var controllerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Controller Readiness")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(XboxDashboardPalette.primary)
                    Text("Xbox Studio keeps controller and Bluetooth checks at the top, then hands off into official Apple and Xbox surfaces when you need support.")
                        .font(.subheadline)
                        .foregroundStyle(XboxDashboardPalette.secondary)
                }
                Spacer()
            }

            controllerStateCard

            HStack(spacing: 10) {
                heroButton("Open Cloud Gaming", systemImage: "cloud.fill") { model.openCloudGaming() }
                heroButton("Open Remote Play", systemImage: "play.tv.fill") { model.openRemotePlay() }
                Button {
                    model.openXboxControllerGuide()
                } label: {
                    Label("Xbox Controller Help", systemImage: "questionmark.circle")
                }
                .buttonStyle(.bordered)
            }

            if model.controllers.controllers.isEmpty {
                emptyCard(
                    title: "No controller rows yet",
                    detail: "Once a controller is visible through Apple's GameController framework, it will appear here with an Xbox-family hint and current-device badge."
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Detected Controllers")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(XboxDashboardPalette.primary)

                    ForEach(model.controllers.controllers) { controller in
                        HStack(alignment: .center, spacing: 14) {
                            Image(systemName: controller.isXboxFamily ? "gamecontroller.fill" : "gamecontroller")
                                .font(.title3)
                                .foregroundStyle(controller.isXboxFamily ? XboxDashboardPalette.accent : XboxDashboardPalette.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(controller.name)
                                        .font(.headline)
                                        .foregroundStyle(XboxDashboardPalette.primary)
                                    if controller.isCurrent {
                                        capsuleLabel("Current", color: Color.blue)
                                    }
                                    if controller.isXboxFamily {
                                        capsuleLabel("Xbox", color: XboxDashboardPalette.accent)
                                    }
                                }
                                Text(controller.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(XboxDashboardPalette.secondary)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(cardBackground)
                    }
                }
            }
        }
    }

    private var controllerStateCard: some View {
        let card = model.controllers.primaryCard

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: card.symbolName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(card.level.color)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(card.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(XboxDashboardPalette.primary)
                        if let badge = card.badge {
                            capsuleLabel(badge, color: card.level.color)
                        }
                    }

                    Text(card.detail)
                        .font(.subheadline)
                        .foregroundStyle(XboxDashboardPalette.secondary)

                    Text(model.controllers.summaryDetail)
                        .font(.footnote)
                        .foregroundStyle(XboxDashboardPalette.secondary.opacity(0.9))
                }

                Spacer()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                ForEach(card.actions) { action in
                    controllerActionButton(action)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var connectivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Connectivity and Official Surfaces")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(XboxDashboardPalette.primary)
                Spacer()
                Button("Refresh Checks") {
                    model.refresh()
                }
                .buttonStyle(.bordered)
            }

            dashboardCard(
                title: "Xbox Web Reachability",
                value: model.connectivity.headline,
                subtitle: "\(model.connectivity.detail) • \(model.connectivity.checkedAtLabel)",
                icon: model.connectivity.level.symbolName,
                tint: model.connectivity.level.color
            )

            ForEach(model.connectivity.probes) { probe in
                HStack(spacing: 12) {
                    Image(systemName: probe.status.symbolName)
                        .foregroundStyle(probe.status.color)
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(probe.name)
                            .font(.headline)
                            .foregroundStyle(XboxDashboardPalette.primary)
                        Text(probe.summary)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(XboxDashboardPalette.secondary)
                        Text("\(probe.destination) • \(probe.detail)")
                            .font(.caption)
                            .foregroundStyle(XboxDashboardPalette.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(cardBackground)
            }
        }
    }

    private var capturesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Capture Inbox")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(XboxDashboardPalette.primary)
                Spacer()
                Button("Import Files") {
                    showImporter = true
                }
                .buttonStyle(.bordered)
                Button("Open Folder") {
                    model.openCaptureFolder()
                }
                .buttonStyle(.borderedProminent)
            }

            Text("Sign in through official Microsoft or Xbox pages in your browser, download or export captures there, then drag them into this local inbox for quick reveal in Finder.")
                .font(.subheadline)
                .foregroundStyle(XboxDashboardPalette.secondary)

            captureDropZone

            if let message = model.lastImportMessage {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(XboxDashboardPalette.accent)
            } else if let error = model.lastError {
                Text(error)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.orange)
            }

            if model.captures.isEmpty {
                emptyCard(
                    title: "Nothing imported yet",
                    detail: "The inbox accepts common Xbox-friendly image and video formats such as .mp4, .mov, .png, .jpg, and .heic."
                )
            } else {
                ForEach(model.captures) { asset in
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(asset.badge == "Video" ? Color.black.opacity(0.08) : Color.green.opacity(0.12))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: asset.badge == "Video" ? "film.stack.fill" : "photo.fill")
                                    .foregroundStyle(asset.badge == "Video" ? Color.black.opacity(0.68) : XboxDashboardPalette.accent)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(asset.title)
                                    .font(.headline)
                                    .foregroundStyle(XboxDashboardPalette.primary)
                                capsuleLabel(asset.badge, color: asset.badge == "Video" ? Color.black.opacity(0.7) : XboxDashboardPalette.accent)
                            }
                            Text(asset.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(XboxDashboardPalette.secondary)
                        }

                        Spacer()

                        Button("Reveal") {
                            model.revealCapture(asset)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(16)
                    .background(cardBackground)
                }
            }
        }
    }

    private var boundarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What This App Can and Cannot Do")
                .font(.title3.weight(.bold))
                .foregroundStyle(XboxDashboardPalette.primary)

            VStack(alignment: .leading, spacing: 10) {
                bullet("Can keep controller and Bluetooth readiness front and center on the Mac.")
                bullet("Can open official Apple pairing guidance and Xbox controller help or firmware guidance.")
                bullet("Can launch official Xbox Cloud Gaming, Remote Play, account, and support surfaces quickly.")
                bullet("Can test whether the main Xbox web surfaces are reachable from your current connection.")
                bullet("Can import downloaded or exported captures into a local inbox you can reveal in Finder.")
                bullet("Cannot silently control console power, installs, messages, or private Xbox libraries without documented Microsoft support.")
            }
            .padding(18)
            .background(cardBackground)
        }
    }

    private var captureDropZone: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: isDropTargeted ? "arrow.down.doc.fill" : "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(isDropTargeted ? XboxDashboardPalette.accent : XboxDashboardPalette.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(isDropTargeted ? "Release to import captures" : "Drop Xbox clips or screenshots here")
                        .font(.headline)
                        .foregroundStyle(XboxDashboardPalette.primary)
                    Text("This copies the files into \(model.captureDirectory.lastPathComponent) so the newest captures stay easy to reveal later.")
                        .font(.subheadline)
                        .foregroundStyle(XboxDashboardPalette.secondary)
                }
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(isDropTargeted ? XboxDashboardPalette.accent.opacity(0.12) : XboxDashboardPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            isDropTargeted ? XboxDashboardPalette.accent : XboxDashboardPalette.border,
                            style: StrokeStyle(lineWidth: isDropTargeted ? 2 : 1, dash: isDropTargeted ? [8, 6] : [])
                        )
                )
        )
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let validProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !validProviders.isEmpty else { return false }

        Task {
            var urls: [URL] = []
            for provider in validProviders {
                if let url = await provider.loadDroppedFileURL() {
                    urls.append(url)
                }
            }
            if !urls.isEmpty {
                await MainActor.run {
                    model.importCaptureFiles(from: urls)
                }
            }
        }
        return true
    }

    @ViewBuilder
    private func controllerActionButton(_ action: XboxControllerAction) -> some View {
        let button = Button {
            model.performControllerAction(action)
        } label: {
            Label(action.title, systemImage: action.systemImage)
                .frame(maxWidth: .infinity)
        }

        if action.isPrimary {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    private func dashboardCard(title: String, value: String, subtitle: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(XboxDashboardPalette.primary)
            }
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(XboxDashboardPalette.primary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(XboxDashboardPalette.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
    }

    private func emptyCard(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(XboxDashboardPalette.primary)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(XboxDashboardPalette.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(XboxDashboardPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(XboxDashboardPalette.border, lineWidth: 1)
            )
    }

    private func capsuleLabel(_ value: String, color: Color) -> some View {
        Text(value)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.12))
            )
            .foregroundStyle(color)
    }

    private func heroButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(.borderedProminent)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(XboxDashboardPalette.accent)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(XboxDashboardPalette.secondary)
        }
    }
}

private extension NSItemProvider {
    func loadDroppedFileURL() async -> URL? {
        await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data {
                    continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil))
                    return
                }

                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }
}
