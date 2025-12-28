//
//  InversionSettings.swift
//  Invar
//

import Foundation

struct InversionSettings: Equatable {
    var contrast: Double
    var brightness: Double
    var gamma: Double

    static let defaults = InversionSettings(contrast: 1.4, brightness: -0.08, gamma: 1.2)
    static let notificationName = Notification.Name("InversionSettingsChanged")

    static var current: InversionSettings {
        let defaults = InversionSettings.defaults
        let store = UserDefaults.standard
        let contrast = store.object(forKey: Keys.contrast) as? Double ?? defaults.contrast
        let brightness = store.object(forKey: Keys.brightness) as? Double ?? defaults.brightness
        let gamma = store.object(forKey: Keys.gamma) as? Double ?? defaults.gamma
        return InversionSettings(contrast: contrast, brightness: brightness, gamma: gamma)
    }

    static func update(_ settings: InversionSettings) {
        let store = UserDefaults.standard
        store.set(settings.contrast, forKey: Keys.contrast)
        store.set(settings.brightness, forKey: Keys.brightness)
        store.set(settings.gamma, forKey: Keys.gamma)
        NotificationCenter.default.post(name: InversionSettings.notificationName, object: nil)
    }

    private enum Keys {
        static let contrast = "inversion.contrast"
        static let brightness = "inversion.brightness"
        static let gamma = "inversion.gamma"
    }
}
