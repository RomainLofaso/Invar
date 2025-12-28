//
//  InversionOverlayWindow.swift
//  Invar
//

import AppKit

final class InversionOverlayWindow: NSWindow, InversionDisplayWindow {
    private let overlayView: InversionOverlayView

    init(region: CGRect) {
        overlayView = InversionOverlayView(frame: NSRect(origin: .zero, size: region.size))
        super.init(
            contentRect: region,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        contentView = overlayView
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        level = .screenSaver
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func present() {
        orderFrontRegardless()
    }

    func update(image: CGImage?) {
        overlayView.update(image: image)
    }

    var nsWindow: NSWindow { self }
}
