//
//  SelectionOverlayView.swift
//  Invar
//

import AppKit

final class SelectionOverlayView: NSView {
    var onSelection: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private let screenFrame: CGRect
    private var selectionStart: CGPoint?
    private var selectionEnd: CGPoint?

    init(frame frameRect: NSRect, screenFrame: CGRect) {
        self.screenFrame = screenFrame
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        selectionStart = point
        selectionEnd = point
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard selectionStart != nil else { return }
        selectionEnd = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let rectInView = selectionRectInView() else {
            cancelSelection()
            return
        }

        let rectInWindow = convert(rectInView, to: nil)
        guard let window = window else {
            cancelSelection()
            return
        }

        let rectInScreen = window.convertToScreen(rectInWindow)
        let clamped = clamp(rectInScreen, to: screenFrame)

        if clamped.width < 1 || clamped.height < 1 {
            cancelSelection()
            return
        }

        onSelection?(clamped)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 || event.characters == "\u{1b}" {
            cancelSelection()
            return
        }
        super.keyDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.25).setFill()
        dirtyRect.fill()

        if let rect = selectionRectInView() {
            NSColor.white.withAlphaComponent(0.15).setFill()
            rect.fill()

            NSColor.white.setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 2
            path.stroke()
        }
    }

    private func selectionRectInView() -> NSRect? {
        guard let start = selectionStart, let end = selectionEnd else {
            return nil
        }

        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)

        return NSRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func clamp(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        var clamped = rect
        if clamped.origin.x < bounds.minX {
            clamped.origin.x = bounds.minX
        }
        if clamped.origin.y < bounds.minY {
            clamped.origin.y = bounds.minY
        }
        if clamped.maxX > bounds.maxX {
            clamped.size.width = bounds.maxX - clamped.origin.x
        }
        if clamped.maxY > bounds.maxY {
            clamped.size.height = bounds.maxY - clamped.origin.y
        }
        if clamped.size.width < 0 {
            clamped.size.width = 0
        }
        if clamped.size.height < 0 {
            clamped.size.height = 0
        }
        return clamped
    }

    private func cancelSelection() {
        onCancel?()
    }
}
