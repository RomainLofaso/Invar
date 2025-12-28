//
//  HotKeyManager.swift
//  Invar
//

import Carbon.HIToolbox
import Foundation

final class HotKeyManager {
    typealias Handler = () -> Void

    private let handler: Handler
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let hotKeyID: EventHotKeyID

    init(keyCode: UInt32, modifiers: UInt32, handler: @escaping Handler) {
        self.handler = handler
        self.hotKeyID = EventHotKeyID(signature: HotKeyManager.signature, id: 1)
        registerHotKey(keyCode: keyCode, modifiers: modifiers)
        installHandler()
    }

    deinit {
        unregisterHotKey()
        removeHandler()
    }

    private func registerHotKey(keyCode: UInt32, modifiers: UInt32) {
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }
                let instance = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                instance.handle(event: event)
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
    }

    private func removeHandler() {
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    private func handle(event: EventRef?) {
        guard let event else { return }
        var hotKeyID = EventHotKeyID()
        var actualSize: Int = 0
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            &actualSize,
            &hotKeyID
        )
        guard status == noErr else { return }
        if hotKeyID.signature == HotKeyManager.signature {
            handler()
        }
    }

    private static let signature: OSType = 0x43494E56 // 'CINV'
}
