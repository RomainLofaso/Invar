//
//  ScreenRecordingPermissionPanel.swift
//  Invar
//

import AppKit
import SwiftUI

final class ScreenRecordingPermissionPanel: NSWindowController, NSWindowDelegate {
    private let onRequestAccess: () -> Void
    private let onCancel: () -> Void
    private let showsOpenSettings: Bool
    private var didComplete = false

    init(
        showsOpenSettings: Bool,
        onRequestAccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.showsOpenSettings = showsOpenSettings
        self.onRequestAccess = onRequestAccess
        self.onCancel = onCancel

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screen Recording Permission"
        window.isReleasedWhenClosed = false

        super.init(window: window)

        window.delegate = self
        window.contentView = makeHostingView()
        window.center()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard !didComplete else { return }
        didComplete = true
        onCancel()
    }

    private func makeHostingView() -> NSView {
        let view = ScreenRecordingPermissionView(
            showsOpenSettings: showsOpenSettings,
            onContinue: { [weak self] in
                self?.continueTapped()
            },
            onNotNow: { [weak self] in
                self?.cancelTapped()
            },
            onOpenSettings: { [weak self] in
                self?.openSettingsTapped()
            }
        )
        return NSHostingView(rootView: view)
    }

    private func continueTapped() {
        guard !didComplete else { return }
        didComplete = true
        window?.close()
        onRequestAccess()
    }

    private func cancelTapped() {
        guard !didComplete else { return }
        didComplete = true
        window?.close()
        onCancel()
    }

    private func openSettingsTapped() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
        guard !didComplete else { return }
        didComplete = true
        window?.close()
        onCancel()
    }
}
