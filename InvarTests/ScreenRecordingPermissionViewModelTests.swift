import XCTest
@testable import InvarCore

@MainActor
final class ScreenRecordingPermissionViewModelTests: XCTestCase {
    func testRefreshStatus_setsAuthorized_andHidesUI() {
        let service = MockScreenRecordingPermissionService(status: .authorized)
        let viewModel = ScreenRecordingPermissionViewModel(service: service)

        viewModel.refreshStatus()

        XCTAssertEqual(viewModel.authorizationStatus, .authorized)
        XCTAssertFalse(viewModel.shouldShowPermissionUI)
    }

    func testRefreshStatus_setsNotDetermined_andShowsUI() {
        let service = MockScreenRecordingPermissionService(status: .notDetermined)
        let viewModel = ScreenRecordingPermissionViewModel(service: service)

        viewModel.refreshStatus()

        XCTAssertEqual(viewModel.authorizationStatus, .notDetermined)
        XCTAssertTrue(viewModel.shouldShowPermissionUI)
    }

    func testRefreshStatus_setsDenied_andShowsUI() {
        let service = MockScreenRecordingPermissionService(status: .denied)
        let viewModel = ScreenRecordingPermissionViewModel(service: service)

        viewModel.refreshStatus()

        XCTAssertEqual(viewModel.authorizationStatus, .denied)
        XCTAssertTrue(viewModel.shouldShowPermissionUI)
    }

    func testRequestPermission_callsService_andRefreshes() {
        let service = MockScreenRecordingPermissionService(status: .notDetermined)
        service.nextStatusAfterRequest = .authorized
        let viewModel = ScreenRecordingPermissionViewModel(service: service)

        viewModel.requestPermission()

        XCTAssertEqual(service.requestCallCount, 1)
        XCTAssertEqual(viewModel.authorizationStatus, .authorized)
        XCTAssertFalse(viewModel.shouldShowPermissionUI)
    }
}

final class MockScreenRecordingPermissionService: ScreenRecordingPermissionService {
    var status: ScreenRecordingAuthorizationStatus
    var nextStatusAfterRequest: ScreenRecordingAuthorizationStatus?
    private(set) var requestCallCount = 0

    init(status: ScreenRecordingAuthorizationStatus) {
        self.status = status
    }

    func authorizationStatus() -> ScreenRecordingAuthorizationStatus {
        status
    }

    func requestAuthorization() {
        requestCallCount += 1
        if let nextStatusAfterRequest {
            status = nextStatusAfterRequest
        }
    }
}
