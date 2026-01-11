//
//  MacOSScreenRecordingPermissionService.swift
//  Invar
//

import CoreGraphics
import Foundation
import InvarCore

final class MacOSScreenRecordingPermissionService: ScreenRecordingPermissionService {
    func authorizationStatus() -> ScreenRecordingAuthorizationStatus {
        if CGPreflightScreenCaptureAccess() {
            return .authorized
        }
        // CGPreflightScreenCaptureAccess cannot distinguish between first-run and denial.
        return hasRequestedAccess ? .denied : .notDetermined
    }

    func requestAuthorization() {
        hasRequestedAccess = true
        _ = CGRequestScreenCaptureAccess()
    }

    private var hasRequestedAccess: Bool {
        get { UserDefaults.standard.bool(forKey: "ScreenRecordingPermissionRequested") }
        set { UserDefaults.standard.set(newValue, forKey: "ScreenRecordingPermissionRequested") }
    }
}
