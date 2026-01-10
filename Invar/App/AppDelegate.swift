//
//  AppDelegate.swift
//  Invar
//

import AppKit
import Carbon.HIToolbox
import Combine
import InvarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var hotKeyManager: HotKeyManager?
    private let permissionStore = ScreenRecordingPermissionStore(authorizer: ScreenRecordingPermissionAuthorizerMacOS())
    private lazy var permissionPresenter = ScreenRecordingPermissionPresenter(store: permissionStore)
    private var permissionStateObserver: AnyCancellable?
    private var activeObserver: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.mainMenu = NSMenu()
        DispatchQueue.main.async {
            self.statusBarController = StatusBarController(
                permissionStore: self.permissionStore,
                permissionPresenter: self.permissionPresenter
            )
            self.observePermissionState()
            self.permissionStore.refresh()
            self.installActiveObserver()
            self.installHotKey()
        }
    }

    private func observePermissionState() {
        permissionStateObserver = permissionStore.$state.sink { [weak self] state in
            guard state == .missingPermission else { return }
            self?.permissionPresenter.present(showsOpenSettings: false)
        }
    }

    private func installActiveObserver() {
        activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let store = self.permissionStore
            Task { @MainActor in
                store.refresh()
            }
        }
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
