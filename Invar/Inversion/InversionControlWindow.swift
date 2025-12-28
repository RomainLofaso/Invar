//
//  InversionControlWindow.swift
//  Invar
//

import AppKit

final class InversionControlWindow: NSPanel {
    private let controlView: InversionControlView

    init(
        region: CGRect,
        onClose: @escaping () -> Void,
        onMove: @escaping (NSPoint) -> Void
    ) {
        let size = NSSize(width: 160, height: 30)
        let frame = NSRect(origin: .zero, size: size)
        self.controlView = InversionControlView(
            frame: frame,
            onClose: onClose,
            onDragDelta: onMove
        )
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .screenSaver
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false

        contentView = controlView
        updatePosition(region: region)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func updatePosition(region: CGRect) {
        let inset: CGFloat = 8
        let x = region.maxX - frame.width - inset
        let y = region.maxY - frame.height - inset
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    func present() {
        orderFrontRegardless()
    }
}

private final class InversionControlView: NSView {
    private let onClose: () -> Void
    private let onDragDelta: (NSPoint) -> Void
    private let closeButton: NSButton
    private let label: NSTextField
    private var dragActive = false
    private var lastScreenPoint: NSPoint = .zero

    init(
        frame frameRect: NSRect,
        onClose: @escaping () -> Void,
        onDragDelta: @escaping (NSPoint) -> Void
    ) {
        self.onClose = onClose
        self.onDragDelta = onDragDelta
        self.closeButton = NSButton(title: "x", target: nil, action: nil)
        self.label = NSTextField(labelWithString: "Drag to move")
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.7).cgColor

        closeButton.target = self
        closeButton.action = #selector(closeTapped)
        closeButton.bezelStyle = .texturedRounded
        closeButton.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        closeButton.frame = NSRect(x: bounds.width - 26, y: 4, width: 20, height: bounds.height - 8)
        addSubview(closeButton)

        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.frame = NSRect(x: 10, y: 6, width: bounds.width - 40, height: bounds.height - 12)
        addSubview(label)

    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if closeButton.frame.contains(point) {
            return closeButton
        }
        return self
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
        onDragDelta(delta)
    }

    override func mouseUp(with event: NSEvent) {
        dragActive = false
    }

    private func screenPoint(for event: NSEvent) -> NSPoint {
        guard let window else { return .zero }
        let rect = NSRect(origin: event.locationInWindow, size: .zero)
        return window.convertToScreen(rect).origin
    }

    @objc private func closeTapped() {
        onClose()
    }
}
