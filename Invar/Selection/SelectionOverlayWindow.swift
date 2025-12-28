//
//  SelectionOverlayWindow.swift
//  Invar
//

import AppKit

final class SelectionOverlayWindow: NSWindow {
    private let selectionView: SelectionOverlayView

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        selectionView = SelectionOverlayView(
            frame: NSRect(origin: .zero, size: contentRect.size),
            screenFrame: contentRect
        )
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        contentView = selectionView
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var canBecomeKey: Bool {
        true
    }

    convenience init(
        screen: NSScreen,
        onSelection: @escaping (CGRect) -> Void,
        onCancel: @escaping () -> Void
    ) {
        let frame = screen.frame
        self.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)

        selectionView.onSelection = onSelection
        selectionView.onCancel = onCancel

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        level = .screenSaver
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = selectionView
    }

    func present() {
        makeKeyAndOrderFront(nil)
        selectionView.window?.makeFirstResponder(selectionView)
        NSApp.activate(ignoringOtherApps: true)
    }
}
