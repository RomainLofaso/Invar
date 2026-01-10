import Foundation

@MainActor
public final class CaptureCoordinator {
    private let permissionStore: ScreenRecordingPermissionStore
    private let permissionPresenter: ScreenRecordingPermissionPresenting
    private let regionSelector: RegionSelecting
    private let sessionFactory: InversionSessionCreating
    private let alertPresenter: AlertPresenting
    private let captureGate: CaptureGate
    private var selectedRegion: CaptureRegion?
    private var selectedScreen: ScreenDescriptor?
    private var inversionSession: InversionSessionHandling?
    private var windowMode: InversionWindowMode

    public init(
        permissionStore: ScreenRecordingPermissionStore,
        permissionPresenter: ScreenRecordingPermissionPresenting,
        regionSelector: RegionSelecting,
        sessionFactory: InversionSessionCreating,
        alertPresenter: AlertPresenting,
        windowMode: InversionWindowMode
    ) {
        self.permissionStore = permissionStore
        self.permissionPresenter = permissionPresenter
        self.regionSelector = regionSelector
        self.sessionFactory = sessionFactory
        self.alertPresenter = alertPresenter
        self.windowMode = windowMode
        self.captureGate = CaptureGate(permissionStore: permissionStore)
    }

    public func beginRegionSelection() {
        captureGate.attemptStart(
            onGranted: { [weak self] in
                guard let self else { return }
                regionSelector.beginSelection(
                    onSelection: { [weak self] region, screen in
                        guard let self else { return }
                        self.selectedRegion = region
                        self.selectedScreen = screen
                        self.startInversionIfPossible()
                    },
                    onCancel: {}
                )
            },
            onMissing: { [weak self] in
                self?.permissionPresenter.present(showsOpenSettings: true)
            }
        )
    }

    public func setWindowMode(_ mode: InversionWindowMode) {
        windowMode = mode
        if let session = inversionSession {
            selectedRegion = session.currentRegion
            selectedScreen = session.currentScreen
            session.stop()
            inversionSession = nil
            startInversionIfPossible()
        }
    }

    public func disableInversion() {
        inversionSession?.stop()
        inversionSession = nil
    }

    private func startInversionIfPossible() {
        guard let selectedRegion, let selectedScreen else {
            alertPresenter.showAlert(
                title: "No Region Selected",
                message: "Select a region before enabling inversion."
            )
            return
        }

        if inversionSession != nil {
            inversionSession?.stop()
            inversionSession = nil
        }

        captureGate.attemptStart(
            onGranted: { [weak self] in
                guard let self else { return }
                let session = sessionFactory.makeSession(
                    region: selectedRegion,
                    screen: selectedScreen,
                    mode: windowMode
                ) { [weak self] in
                    self?.disableInversion()
                }
                inversionSession = session
                session.start()
            },
            onMissing: { [weak self] in
                self?.permissionPresenter.present(showsOpenSettings: true)
            }
        )
    }
}
