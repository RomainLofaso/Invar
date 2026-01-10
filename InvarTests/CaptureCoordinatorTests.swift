import XCTest
@testable import InvarCore

@MainActor
final class CaptureCoordinatorTests: XCTestCase {
    func testBeginRegionSelection_showsPermissionPrompt_whenMissing() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: false, requestResult: false)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        let presenter = FakePermissionPresenter()
        let selector = FakeRegionSelector()
        let factory = FakeSessionFactory()
        let alerts = FakeAlertPresenter()
        let coordinator = CaptureCoordinator(
            permissionStore: store,
            permissionPresenter: presenter,
            regionSelector: selector,
            sessionFactory: factory,
            alertPresenter: alerts,
            windowMode: .overlay
        )

        coordinator.beginRegionSelection()

        XCTAssertEqual(presenter.presentCallCount, 1)
        XCTAssertEqual(presenter.lastShowsOpenSettings, true)
        XCTAssertEqual(selector.beginCallCount, 0)
        XCTAssertEqual(factory.makeCallCount, 0)
    }

    func testBeginRegionSelection_startsSelection_whenGranted() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: true, requestResult: false)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        let presenter = FakePermissionPresenter()
        let selector = FakeRegionSelector()
        let factory = FakeSessionFactory()
        let alerts = FakeAlertPresenter()
        let coordinator = CaptureCoordinator(
            permissionStore: store,
            permissionPresenter: presenter,
            regionSelector: selector,
            sessionFactory: factory,
            alertPresenter: alerts,
            windowMode: .overlay
        )

        coordinator.beginRegionSelection()

        XCTAssertEqual(selector.beginCallCount, 1)
        XCTAssertEqual(presenter.presentCallCount, 0)
    }

    func testSelection_startsSession_whenPermissionGranted() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: true, requestResult: false)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        let presenter = FakePermissionPresenter()
        let selector = FakeRegionSelector()
        let factory = FakeSessionFactory()
        let alerts = FakeAlertPresenter()
        let coordinator = CaptureCoordinator(
            permissionStore: store,
            permissionPresenter: presenter,
            regionSelector: selector,
            sessionFactory: factory,
            alertPresenter: alerts,
            windowMode: .standard
        )

        coordinator.beginRegionSelection()
        selector.completeSelection(region: CaptureRegion(x: 10, y: 20, width: 30, height: 40), screen: ScreenDescriptor(displayID: 1))

        XCTAssertEqual(factory.makeCallCount, 1)
        XCTAssertEqual(factory.lastMode, .standard)
        XCTAssertEqual(factory.lastRegion, CaptureRegion(x: 10, y: 20, width: 30, height: 40))
        XCTAssertEqual(factory.lastScreen, ScreenDescriptor(displayID: 1))
        XCTAssertEqual(factory.lastSession?.startCallCount, 1)
    }

    func testSelection_showsPermissionPrompt_whenPermissionRevokedBeforeStart() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: true, requestResult: false)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        let presenter = FakePermissionPresenter()
        let selector = FakeRegionSelector()
        let factory = FakeSessionFactory()
        let alerts = FakeAlertPresenter()
        let coordinator = CaptureCoordinator(
            permissionStore: store,
            permissionPresenter: presenter,
            regionSelector: selector,
            sessionFactory: factory,
            alertPresenter: alerts,
            windowMode: .overlay
        )

        coordinator.beginRegionSelection()
        authorizer.preflightResult = false
        selector.completeSelection(region: CaptureRegion(x: 0, y: 0, width: 10, height: 10), screen: ScreenDescriptor(displayID: 2))

        XCTAssertEqual(presenter.presentCallCount, 1)
        XCTAssertEqual(factory.makeCallCount, 0)
    }
}

final class FakePermissionPresenter: ScreenRecordingPermissionPresenting {
    private(set) var presentCallCount = 0
    private(set) var lastShowsOpenSettings: Bool?

    func present(showsOpenSettings: Bool) {
        presentCallCount += 1
        lastShowsOpenSettings = showsOpenSettings
    }
}

final class FakeRegionSelector: RegionSelecting {
    private(set) var beginCallCount = 0
    private var onSelection: ((CaptureRegion, ScreenDescriptor) -> Void)?
    private var onCancel: (() -> Void)?

    func beginSelection(
        onSelection: @escaping (CaptureRegion, ScreenDescriptor) -> Void,
        onCancel: @escaping () -> Void
    ) {
        beginCallCount += 1
        self.onSelection = onSelection
        self.onCancel = onCancel
    }

    func completeSelection(region: CaptureRegion, screen: ScreenDescriptor) {
        onSelection?(region, screen)
    }

    func cancelSelection() {
        onCancel?()
    }
}

final class FakeSessionFactory: InversionSessionCreating {
    private(set) var makeCallCount = 0
    private(set) var lastRegion: CaptureRegion?
    private(set) var lastScreen: ScreenDescriptor?
    private(set) var lastMode: InversionWindowMode?
    private(set) var lastSession: FakeSession?

    func makeSession(
        region: CaptureRegion,
        screen: ScreenDescriptor,
        mode: InversionWindowMode,
        onStop: @escaping () -> Void
    ) -> InversionSessionHandling {
        makeCallCount += 1
        lastRegion = region
        lastScreen = screen
        lastMode = mode
        let session = FakeSession(region: region, screen: screen, onStop: onStop)
        lastSession = session
        return session
    }
}

final class FakeSession: InversionSessionHandling {
    private let onStop: () -> Void
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    var currentRegion: CaptureRegion
    var currentScreen: ScreenDescriptor

    init(region: CaptureRegion, screen: ScreenDescriptor, onStop: @escaping () -> Void) {
        self.currentRegion = region
        self.currentScreen = screen
        self.onStop = onStop
    }

    func start() {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
        onStop()
    }
}

final class FakeAlertPresenter: AlertPresenting {
    private(set) var messages: [(String, String)] = []

    func showAlert(title: String, message: String) {
        messages.append((title, message))
    }
}
