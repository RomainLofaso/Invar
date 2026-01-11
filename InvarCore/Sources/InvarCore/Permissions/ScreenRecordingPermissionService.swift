public protocol ScreenRecordingPermissionService {
    func authorizationStatus() -> ScreenRecordingAuthorizationStatus
    func requestAuthorization()
}
