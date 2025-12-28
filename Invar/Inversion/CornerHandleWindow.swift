//
//  CornerHandleWindow.swift
//  Invar
//

import AppKit

enum CornerHandle {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

final class CornerHandleWindow: NSPanel {
    private let handleView: CornerHandleView
    private let corner: CornerHandle

    init(corner: CornerHandle, onDrag: @escaping (CornerHandle, NSPoint) -> Void) {
        self.corner = corner
        let size = NSSize(width: 12, height: 12)
        let frame = NSRect(origin: .zero, size: size)
        self.handleView = CornerHandleView(frame: frame, corner: corner, onDrag: onDrag)
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 2)
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false
        contentView = handleView
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func updatePosition(region: CGRect) {
        let origin: NSPoint
        switch corner {
        case .topLeft:
            origin = NSPoint(x: region.minX - 6, y: region.maxY - 6)
        case .topRight:
            origin = NSPoint(x: region.maxX - 6, y: region.maxY - 6)
        case .bottomLeft:
            origin = NSPoint(x: region.minX - 6, y: region.minY - 6)
        case .bottomRight:
            origin = NSPoint(x: region.maxX - 6, y: region.minY - 6)
        }
        setFrameOrigin(origin)
    }

    func present() {
        orderFrontRegardless()
    }
}

private final class CornerHandleView: NSView {
    private let corner: CornerHandle
    private let onDrag: (CornerHandle, NSPoint) -> Void
    private var dragActive = false
    private var lastScreenPoint: NSPoint = .zero

    init(frame frameRect: NSRect, corner: CornerHandle, onDrag: @escaping (CornerHandle, NSPoint) -> Void) {
        self.corner = corner
        self.onDrag = onDrag
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 3
        layer?.backgroundColor = NSColor.clear.cgColor
        alphaValue = 0.01
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        dragActive = true
        lastScreenPoint = screenPoint(for: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragActive else { return }
        let current = screenPoint(for: event)
        let delta = NSPoint(x: current.x - lastScreenPoint.x, y: current.y - lastScreenPoint.y)
        lastScreenPoint = current
        onDrag(corner, delta)
    }

    override func mouseUp(with event: NSEvent) {
        dragActive = false
    }

    private func screenPoint(for event: NSEvent) -> NSPoint {
        guard let window else { return .zero }
        let rect = NSRect(origin: event.locationInWindow, size: .zero)
        return window.convertToScreen(rect).origin
    }
}
