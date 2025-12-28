//
//  InversionStandardWindow.swift
//  Invar
//

import AppKit

final class InversionStandardWindow: NSWindow, InversionDisplayWindow {
    private let overlayView: InversionOverlayView

    init(region: CGRect) {
        overlayView = InversionOverlayView(frame: NSRect(origin: .zero, size: region.size))
        super.init(
            contentRect: region,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        title = "Inversion"
        contentView = overlayView
        overlayView.autoresizingMask = [.width, .height]
        isReleasedWhenClosed = false
        level = .floating
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func present() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func update(image: CGImage?) {
        overlayView.update(image: image)
    }

    var nsWindow: NSWindow { self }
}
