//
//  AppDelegate.swift
//  Invar
//

import AppKit
import Carbon.HIToolbox
import Combine
import InvarCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusBarController: StatusBarController?
    private var hotKeyManager: HotKeyManager?
    private let permissionService = MacOSScreenRecordingPermissionService()
    private lazy var permissionViewModel = ScreenRecordingPermissionViewModel(service: permissionService)
    private var permissionUIObserver: AnyCancellable?
    private var activeObserver: Any?
    private var permissionWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.mainMenu = NSMenu()
        DispatchQueue.main.async {
            self.statusBarController = StatusBarController(
                permissionViewModel: self.permissionViewModel
            )
            self.observePermissionUI()
            self.permissionViewModel.refreshStatus()
            self.installActiveObserver()
            self.installHotKey()
        }
    }

    private func observePermissionUI() {
        permissionUIObserver = permissionViewModel.$shouldShowPermissionUI
            .removeDuplicates()
            .sink { [weak self] shouldShow in
                guard let self else { return }
                if shouldShow {
                    self.showPermissionWindow()
                } else {
                    self.hidePermissionWindow()
                }
            }
    }

    private func showPermissionWindow() {
        guard permissionWindow == nil else { return }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screen Recording Permission"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: ScreenRecordingPermissionView(viewModel: permissionViewModel))
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        permissionWindow = window
    }

    private func hidePermissionWindow() {
        permissionWindow?.close()
        permissionWindow = nil
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == permissionWindow else { return }
        permissionWindow = nil
    }

    private func installActiveObserver() {
        activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.permissionViewModel.refreshStatus()
        }
    }

    private func installHotKey() {
        let modifiers = UInt32(optionKey | controlKey)
        hotKeyManager = HotKeyManager(keyCode: UInt32(kVK_Space), modifiers: modifiers) { [weak self] in
            self?.statusBarController?.beginRegionSelection()
        }
    }
}
