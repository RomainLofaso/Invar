import Foundation

public protocol ScreenRecordingAuthorizing {
    func preflight() -> Bool
    func requestAccess() async -> Bool
}

public protocol ScreenRecordingPermissionPresenting {
    func present(showsOpenSettings: Bool)
}

public protocol RegionSelecting {
    func beginSelection(
        onSelection: @escaping (CaptureRegion, ScreenDescriptor) -> Void,
        onCancel: @escaping () -> Void
    )
}

public protocol InversionSessionHandling: AnyObject {
    var currentRegion: CaptureRegion { get }
    var currentScreen: ScreenDescriptor { get }
    func start()
    func stop()
}

public protocol InversionSessionCreating {
    func makeSession(
        region: CaptureRegion,
        screen: ScreenDescriptor,
        mode: InversionWindowMode,
        onStop: @escaping () -> Void
    ) -> InversionSessionHandling
}

public protocol AlertPresenting {
    func showAlert(title: String, message: String)
}
