//
//  ScreenCapture.swift
//  Invar
//

import CoreGraphics

@_silgen_name("CGWindowListCreateImage")
private func CGWindowListCreateImageShim(
    _ screenBounds: CGRect,
    _ listOption: CGWindowListOption,
    _ windowID: CGWindowID,
    _ imageOption: CGWindowImageOption
) -> CGImage?

final class ScreenCapture {
    func canCapture(region: CGRect) -> Bool {
        let probe = CGRect(x: region.minX, y: region.minY, width: 1, height: 1)
        return capture(region: probe, belowWindowID: nil) != nil
    }


    func capture(region: CGRect, belowWindowID: CGWindowID?) -> CGImage? {
        let option: CGWindowListOption
        let windowID: CGWindowID

        if let belowWindowID {
            option = .optionOnScreenBelowWindow
            windowID = belowWindowID
        } else {
            option = .optionOnScreenOnly
            windowID = kCGNullWindowID
        }

        return CGWindowListCreateImageShim(
            region,
            option,
            windowID,
            [.bestResolution]
        )
    }
}
