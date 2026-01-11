//
//  ScreenDescriptorAdapters.swift
//  Invar
//

import AppKit
import InvarCore

extension CaptureRegion {
    init(_ rect: CGRect) {
        self.init(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

extension ScreenDescriptor {
    init?(screen: NSScreen) {
        guard let displayID = screen.displayID else { return nil }
        self.init(displayID: displayID)
    }
}

extension NSScreen {
    var displayID: Int? {
        guard let id = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return id.intValue
    }

    static func screen(for descriptor: ScreenDescriptor) -> NSScreen? {
        NSScreen.screens.first { $0.displayID == descriptor.displayID } ?? NSScreen.main
    }
}
