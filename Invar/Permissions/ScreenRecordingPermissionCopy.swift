//
//  ScreenRecordingPermissionCopy.swift
//  Invar
//

import Foundation

enum ScreenRecordingPermissionCopy {
    static let title = NSLocalizedString(
        "permission.screenRecording.title",
        value: "Allow screen recording",
        comment: "Title for the pre-permission screen recording panel."
    )
    static let primary = NSLocalizedString(
        "permission.screenRecording.primary",
        value: "Invar locally inverts colors in a selected area of your screen.",
        comment: "Primary permission statement."
    )
    static let secondary = NSLocalizedString(
        "permission.screenRecording.secondary",
        value: "This requires access to read screen pixels and apply the visual effect only inside the region you choose.",
        comment: "Secondary explanation for why screen recording access is needed."
    )
    static let bullet1 = NSLocalizedString(
        "permission.screenRecording.bullet1",
        value: "No video is recorded",
        comment: "Reassurance bullet 1."
    )
    static let bullet2 = NSLocalizedString(
        "permission.screenRecording.bullet2",
        value: "Nothing is stored or shared",
        comment: "Reassurance bullet 2."
    )
    static let bullet3 = NSLocalizedString(
        "permission.screenRecording.bullet3",
        value: "All processing happens on your Mac",
        comment: "Reassurance bullet 3."
    )
}
