//
//  InversionOverlayView.swift
//  Invar
//

import AppKit

final class InversionOverlayView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.contentsGravity = .resize
        layer?.magnificationFilter = .linear
        layer?.minificationFilter = .linear
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let scale = window?.backingScaleFactor {
            layer?.contentsScale = scale
        }
    }

    func update(image: CGImage?) {
        layer?.contents = image
    }

}
