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
                    model.connectivity.level.color.opacity(0.12),
                    XboxDashboardPalette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    statusGrid
                    controllerSection
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

                Text("A macOS menu bar hub for Xbox cloud gaming, Remote Play launch, controller readiness, connectivity checks, and a drag-and-drop capture inbox.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(XboxDashboardPalette.secondary)

                TextField("Optional player label or note", text: $model.playerLabel)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)

                HStack(spacing: 10) {
                    heroButton("Cloud Gaming", systemImage: "cloud.fill") { model.openCloudGaming() }
                    heroButton("Remote Play", systemImage: "play.tv.fill") { model.openRemotePlay() }
                    heroButton("Xbox Account", systemImage: "person.crop.circle") { model.openAccount() }
                    heroButton("Bluetooth", systemImage: "dot.radiowaves.left.and.right") { model.openBluetoothSettings() }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                capsuleLabel(model.connectivity.headline, color: model.connectivity.level.color)
                capsuleLabel(model.controllers.bluetoothTitle, color: model.controllers.bluetoothLevel.color)
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

    private var statusGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            dashboardCard(
                title: "Connectivity",
                value: model.connectivity.detail,
                subtitle: model.connectivity.checkedAtLabel,
                icon: model.connectivity.level.symbolName,
                tint: model.connectivity.level.color
            )
            dashboardCard(
                title: "Bluetooth",
                value: model.controllers.bluetoothTitle,
                subtitle: model.controllers.bluetoothDetail,
                icon: model.controllers.bluetoothLevel.symbolName,
                tint: model.controllers.bluetoothLevel.color
            )
            dashboardCard(
                title: "Controllers",
                value: "\(model.controllers.controllerCount) connected",
                subtitle: model.controllers.controllerCount == 0 ? "No active game controllers right now." : "GameController framework sees active devices.",
                icon: "gamecontroller.fill",
                tint: XboxDashboardPalette.accent
            )
            dashboardCard(
                title: "Capture Inbox",
                value: model.captureDirectory.lastPathComponent,
                subtitle: model.captureDirectory.path,
                icon: "tray.full.fill",
                tint: XboxDashboardPalette.accent
            )
        }
    }

    private var controllerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Controllers and Local Readiness")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(XboxDashboardPalette.primary)
                Spacer()
                Button("Open Bluetooth Settings") {
                    model.openBluetoothSettings()
                }
                .buttonStyle(.bordered)
            }

            Text("Xbox Studio reads Bluetooth state on the Mac and lists controllers visible through Apple's GameController framework. It does not impersonate a private Xbox console API.")
                .font(.subheadline)
                .foregroundStyle(XboxDashboardPalette.secondary)

            if model.controllers.controllers.isEmpty {
                emptyCard(
                    title: "No connected controllers",
                    detail: "Turn Bluetooth on, pair a supported Xbox controller in macOS settings, then come back here to verify the connection."
                )
            } else {
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
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(XboxDashboardPalette.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(XboxDashboardPalette.border, lineWidth: 1)
                            )
                    )
                }
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

            Text("Sign in through official Microsoft or Xbox pages in your browser, export or download captures there, then drag them into this inbox. Xbox Studio organizes the files locally so they are easy to reveal or move anywhere on your Mac.")
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
                    detail: "The inbox accepts common Xbox-friendly image and video formats such as .mp4, .mov, .png, and .jpg."
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
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(XboxDashboardPalette.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(XboxDashboardPalette.border, lineWidth: 1)
                            )
                    )
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
                bullet("Can open official Xbox cloud gaming, Remote Play, account, and support surfaces quickly from the Mac.")
                bullet("Can test whether those web surfaces are reachable from your current connection.")
                bullet("Can show Bluetooth readiness and the controllers macOS currently sees.")
                bullet("Can import downloaded or exported captures into a local inbox you can reveal in Finder.")
                bullet("Cannot silently control console power, library installs, messages, or private capture libraries without documented Microsoft support.")
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(XboxDashboardPalette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(XboxDashboardPalette.border, lineWidth: 1)
                    )
            )
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
                    Text("This copies the files into \(model.captureDirectory.lastPathComponent) so you can reveal them later.")
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
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(XboxDashboardPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(XboxDashboardPalette.border, lineWidth: 1)
                )
        )
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
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(XboxDashboardPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(XboxDashboardPalette.border, lineWidth: 1)
                )
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
