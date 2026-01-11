import Combine
import Foundation

@MainActor
public final class ScreenRecordingPermissionViewModel: ObservableObject {
    @Published public private(set) var authorizationStatus: ScreenRecordingAuthorizationStatus
    @Published public private(set) var shouldShowPermissionUI: Bool

    private let service: ScreenRecordingPermissionService

    public init(service: ScreenRecordingPermissionService) {
        self.service = service
        self.authorizationStatus = .notDetermined
        self.shouldShowPermissionUI = false
    }

    public func refreshStatus() {
        let status = service.authorizationStatus()
        authorizationStatus = status
        shouldShowPermissionUI = status != .authorized
    }

    public func requestPermission() {
        service.requestAuthorization()
        refreshStatus()
    }
}
