//
//  ScreenRecordingPermissionAuthorizerMacOS.swift
//  Invar
//

import CoreGraphics
import Foundation
import InvarCore

struct ScreenRecordingPermissionAuthorizerMacOS: ScreenRecordingAuthorizing {
    func preflight() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: CGRequestScreenCaptureAccess())
            }
        }
    }
}
