//
//  InversionSessionFactoryMacOS.swift
//  Invar
//

import AppKit
import InvarCore

final class InversionSessionFactoryMacOS: InversionSessionCreating {
    func makeSession(
        region: CaptureRegion,
        screen: ScreenDescriptor,
        mode: InversionWindowMode,
        onStop: @escaping () -> Void
    ) -> InversionSessionHandling {
        let targetBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard let resolvedScreen = NSScreen.screen(for: screen) ?? NSScreen.main ?? NSScreen.screens.first else {
            preconditionFailure("No NSScreen available for inversion session.")
        }
        let session = InversionSession(
            region: region.cgRect,
            screen: resolvedScreen,
            mode: mode,
            targetBundleIdentifier: targetBundleIdentifier,
            onStop: onStop
        )
        return InversionSessionAdapter(session: session)
    }
}

final class InversionSessionAdapter: InversionSessionHandling {
    private let session: InversionSession

    init(session: InversionSession) {
        self.session = session
    }

    var currentRegion: CaptureRegion {
        CaptureRegion(session.currentRegion)
    }

    var currentScreen: ScreenDescriptor {
        ScreenDescriptor(screen: session.currentScreen) ?? ScreenDescriptor(displayID: 0)
    }

    func start() {
        session.start()
    }

    func stop() {
        session.stop()
    }
}
