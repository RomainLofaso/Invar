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
