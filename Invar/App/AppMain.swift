//
//  AppMain.swift
//  Invar
//

import AppKit

@main
struct AppMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    @MainActor
    private static var delegate: AppDelegate?
}
