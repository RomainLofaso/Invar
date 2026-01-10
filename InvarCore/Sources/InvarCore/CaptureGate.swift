import Foundation

@MainActor
public struct CaptureGate {
    private let permissionStore: ScreenRecordingPermissionStore

    public init(permissionStore: ScreenRecordingPermissionStore) {
        self.permissionStore = permissionStore
    }

    public func attemptStart(onGranted: () -> Void, onMissing: () -> Void) {
        permissionStore.refresh()
        if permissionStore.state == .granted {
            onGranted()
        } else {
            onMissing()
        }
    }
}
