import Combine
import Foundation

public final class ScreenRecordingPermissionStore: ObservableObject {
    public enum State: Equatable {
        case granted
        case missingPermission
        case requesting
    }

    @Published public private(set) var state: State
    private let authorizer: ScreenRecordingAuthorizing

    public init(authorizer: ScreenRecordingAuthorizing, initialState: State = .missingPermission) {
        self.authorizer = authorizer
        self.state = initialState
    }

    @MainActor
    public func refresh() {
        state = authorizer.preflight() ? .granted : .missingPermission
    }

    @MainActor
    public func requestAccess() async {
        guard state != .requesting else { return }
        state = .requesting
        _ = await authorizer.requestAccess()
        refresh()
    }
}
