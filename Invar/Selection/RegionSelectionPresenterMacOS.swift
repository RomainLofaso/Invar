//
//  RegionSelectionPresenterMacOS.swift
//  Invar
//

import AppKit
import Foundation
import InvarCore

final class RegionSelectionPresenterMacOS: RegionSelecting {
    private var selectionWindow: SelectionOverlayWindow?

    func beginSelection(
        onSelection: @escaping (CaptureRegion, ScreenDescriptor) -> Void,
        onCancel: @escaping () -> Void
    ) {
        guard let screen = screenUnderMouse() else {
            print("Select region failed: no screen found for mouse location.")
            onCancel()
            return
        }

        if let selectionWindow {
            selectionWindow.close()
            self.selectionWindow = nil
        }

        let window = SelectionOverlayWindow(
            screen: screen,
            onSelection: { [weak self] rect in
                guard let self else { return }
                guard let descriptor = ScreenDescriptor(screen: screen) else {
                    onCancel()
                    return
                }
                onSelection(CaptureRegion(rect), descriptor)
                DispatchQueue.main.async { [weak self] in
                    self?.selectionWindow?.close()
                    self?.selectionWindow = nil
                }
            },
            onCancel: { [weak self] in
                print("Selection cancelled")
                DispatchQueue.main.async { [weak self] in
                    self?.selectionWindow?.close()
                    self?.selectionWindow = nil
                }
                onCancel()
            }
        )
        self.selectionWindow = window
        window.present()
    }

    private func screenUnderMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
    }
}
