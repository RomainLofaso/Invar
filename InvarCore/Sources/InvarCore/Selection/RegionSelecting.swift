public protocol RegionSelecting {
    func beginSelection(
        onSelection: @escaping (CaptureRegion, ScreenDescriptor) -> Void,
        onCancel: @escaping () -> Void
    )
}
