//
//  AppDelegate.swift
//  Invar
//

import AppKit
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var hasRequestedScreenRecordingAccess = false
    private var statusBarController: StatusBarController?
    private let screenCapture = ScreenCapture()
    private var hotKeyManager: HotKeyManager?
    private var didRequestScreenRecordingAccess = false
    private var permissionPanel: ScreenRecordingPermissionPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.mainMenu = NSMenu()
        DispatchQueue.main.async {
            self.statusBarController = StatusBarController()
            self.checkScreenRecordingAccess()
            self.installHotKey()
        }
    }

    private func checkScreenRecordingAccess() {
        guard !didRequestScreenRecordingAccess, !Self.hasRequestedScreenRecordingAccess else { return }
        guard !screenCapture.hasPermission() else { return }
        didRequestScreenRecordingAccess = true
        showScreenRecordingPermissionPanel()
    }

    private func showScreenRecordingPermissionPanel() {
        permissionPanel = ScreenRecordingPermissionPanel(
            showsOpenSettings: false,
            onRequestAccess: { [weak self] in
                guard let self else { return }
                Self.hasRequestedScreenRecordingAccess = true
                _ = self.screenCapture.requestPermission()
                self.permissionPanel = nil
            },
            onCancel: { [weak self] in
                self?.permissionPanel = nil
            }
        )
        permissionPanel?.show()
    }

    private func installHotKey() {
        let modifiers = UInt32(optionKey | controlKey)
        hotKeyManager = HotKeyManager(keyCode: UInt32(kVK_Space), modifiers: modifiers) { [weak self] in
            self?.statusBarController?.beginRegionSelection()
        }
    }

    private func showScreenRecordingPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Needed"
        alert.informativeText = "Enable Screen Recording for Invar in System Settings > Privacy & Security > Screen Recording."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
