//
//  ScreenRecordingPermissionPresenter.swift
//  Invar
//

import InvarCore

@MainActor
final class ScreenRecordingPermissionPresenter: ScreenRecordingPermissionPresenting {
    private let store: ScreenRecordingPermissionStore
    private var panel: ScreenRecordingPermissionPanel?

    init(store: ScreenRecordingPermissionStore) {
        self.store = store
    }

    func present(showsOpenSettings: Bool) {
        guard panel == nil else { return }
        panel = ScreenRecordingPermissionPanel(
            showsOpenSettings: showsOpenSettings,
            onRequestAccess: { [weak self] in
                guard let self else { return }
                Task {
                    await self.store.requestAccess()
                }
                self.panel = nil
            },
            onCancel: { [weak self] in
                self?.panel = nil
            }
        )
        panel?.show()
    }
}
