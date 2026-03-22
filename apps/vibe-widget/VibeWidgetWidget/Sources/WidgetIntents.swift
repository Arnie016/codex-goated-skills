import AppIntents
import VibeWidgetCore

protocol QueuedWidgetIntent {
    var action: QueuedWidgetAction { get }
}

extension QueuedWidgetIntent where Self: AppIntent {
    func enqueueAction() {
        SharedStore.shared.enqueue(action: action)
    }
}

struct PlayRecommendedVibeIntent: AppIntent, QueuedWidgetIntent {
    static var title: LocalizedStringResource = "Play Recommended Vibe"
    static var description = IntentDescription("Open the app and play the pinned recommendation.")
    static var openAppWhenRun = true

    var action: QueuedWidgetAction { QueuedWidgetAction(kind: .playRecommended) }

    func perform() async throws -> some IntentResult {
        enqueueAction()
        return .result()
    }
}

struct DimBedroomIntent: AppIntent, QueuedWidgetIntent {
    static var title: LocalizedStringResource = "Dim Bedroom"
    static var description = IntentDescription("Dim the default room lights and open the app.")
    static var openAppWhenRun = true

    var action: QueuedWidgetAction { QueuedWidgetAction(kind: .dimBedroom) }

    func perform() async throws -> some IntentResult {
        enqueueAction()
        return .result()
    }
}

struct RefreshRecommendationsIntent: AppIntent, QueuedWidgetIntent {
    static var title: LocalizedStringResource = "Refresh Recommendations"
    static var description = IntentDescription("Fetch fresh top picks for the widget.")
    static var openAppWhenRun = true

    var action: QueuedWidgetAction { QueuedWidgetAction(kind: .refreshRecommendations) }

    func perform() async throws -> some IntentResult {
        enqueueAction()
        return .result()
    }
}

struct OpenVibePanelIntent: AppIntent, QueuedWidgetIntent {
    static var title: LocalizedStringResource = "Open Vibe Panel"
    static var description = IntentDescription("Open the compact app panel for voice and text control.")
    static var openAppWhenRun = true

    var action: QueuedWidgetAction { QueuedWidgetAction(kind: .openPanel) }

    func perform() async throws -> some IntentResult {
        enqueueAction()
        return .result()
    }
}

struct SetHomeSceneIntent: AppIntent, QueuedWidgetIntent {
    static var title: LocalizedStringResource = "Set Home Scene"
    static var description = IntentDescription("Run an Apple Home scene by name.")
    static var openAppWhenRun = true

    @Parameter(title: "Scene Name")
    var sceneName: String

    var action: QueuedWidgetAction { QueuedWidgetAction(kind: .setScene, sceneName: sceneName) }

    func perform() async throws -> some IntentResult {
        enqueueAction()
        return .result()
    }
}
