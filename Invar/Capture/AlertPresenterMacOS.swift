//
//  AlertPresenterMacOS.swift
//  Invar
//

import AppKit
import InvarCore

struct AlertPresenterMacOS: AlertPresenting {
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
