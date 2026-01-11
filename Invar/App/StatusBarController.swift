//
//  StatusBarController.swift
//  Invar
//

import AppKit
import InvarCore

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let captureCoordinator: CaptureCoordinator
    private var useStandardWindow = UserDefaults.standard.bool(forKey: "useStandardWindow")
    private var contrastSlider: NSSlider?
    private var brightnessSlider: NSSlider?
    private var gammaSlider: NSSlider?
    private lazy var adjustmentsItem: NSMenuItem = {
        let menu = NSMenu()
        let settings = InversionSettings.current

        menu.addItem(makeSliderItem(
            title: "Contrast",
            min: 0.5,
            max: 2.0,
            value: settings.contrast,
            action: #selector(contrastChanged(_:))
        ) { [weak self] slider in
            self?.contrastSlider = slider
        })

        menu.addItem(makeSliderItem(
            title: "Brightness",
            min: -0.5,
            max: 0.5,
            value: settings.brightness,
            action: #selector(brightnessChanged(_:))
        ) { [weak self] slider in
            self?.brightnessSlider = slider
        })

        menu.addItem(makeSliderItem(
            title: "Gamma",
            min: 0.5,
            max: 2.0,
            value: settings.gamma,
            action: #selector(gammaChanged(_:))
        ) { [weak self] slider in
            self?.gammaSlider = slider
        })

        menu.addItem(NSMenuItem.separator())
        let resetItem = NSMenuItem(title: "Reset adjustments", action: #selector(resetAdjustments), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)

        let item = NSMenuItem(title: "Adjustments", action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }()
    private lazy var windowModeItem: NSMenuItem = {
        let item = NSMenuItem(
            title: "Use standard window",
            action: #selector(toggleWindowMode),
            keyEquivalent: "w"
        )
        item.target = self
        item.state = useStandardWindow ? .on : .off
        return item
    }()

    init(permissionViewModel: ScreenRecordingPermissionViewModel) {
        let windowMode: InversionWindowMode = useStandardWindow ? .standard : .overlay
        captureCoordinator = CaptureCoordinator(
            permissionViewModel: permissionViewModel,
            regionSelector: RegionSelectionPresenterMacOS(),
            sessionFactory: InversionSessionFactoryMacOS(),
            alertPresenter: AlertPresenterMacOS(),
            windowMode: windowMode
        )
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let image = NSImage(named: NSImage.Name("StatusBarIcon")) {
            image.isTemplate = true
            statusItem.button?.image = image
        } else if let image = NSImage(systemSymbolName: "circle.lefthalf.filled", accessibilityDescription: "Invert") {
            image.isTemplate = true
            statusItem.button?.image = image
        } else {
            statusItem.button?.title = "◐"
        }
        statusItem.button?.toolTip = "Invar"
        statusItem.isVisible = true
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let selectRegionItem = NSMenuItem(
            title: "Select region…",
            action: #selector(selectRegion),
            keyEquivalent: "s"
        )
        selectRegionItem.target = self

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self

        menu.addItem(selectRegionItem)
        menu.addItem(windowModeItem)
        menu.addItem(adjustmentsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)

        return menu
    }

    @objc private func selectRegion() {
        captureCoordinator.beginRegionSelection()
    }

    func beginRegionSelection() {
        selectRegion()
    }

    @objc private func quit() {
        print("Quit requested")
        NSApp.terminate(nil)
    }

    @objc private func contrastChanged(_ sender: NSSlider) {
        applySettingsChange(contrast: sender.doubleValue, brightness: nil, gamma: nil)
    }

    @objc private func brightnessChanged(_ sender: NSSlider) {
        applySettingsChange(contrast: nil, brightness: sender.doubleValue, gamma: nil)
    }

    @objc private func gammaChanged(_ sender: NSSlider) {
        applySettingsChange(contrast: nil, brightness: nil, gamma: sender.doubleValue)
    }

    @objc private func resetAdjustments() {
        let defaults = InversionSettings.defaults
        contrastSlider?.doubleValue = defaults.contrast
        brightnessSlider?.doubleValue = defaults.brightness
        gammaSlider?.doubleValue = defaults.gamma
        InversionSettings.update(defaults)
    }

    private func applySettingsChange(contrast: Double?, brightness: Double?, gamma: Double?) {
        var settings = InversionSettings.current
        if let contrast { settings.contrast = contrast }
        if let brightness { settings.brightness = brightness }
        if let gamma { settings.gamma = gamma }
        InversionSettings.update(settings)
    }

    private func makeSliderItem(
        title: String,
        min: Double,
        max: Double,
        value: Double,
        action: Selector,
        onCreate: (NSSlider) -> Void
    ) -> NSMenuItem {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 28))
        let label = NSTextField(labelWithString: title)
        label.frame = NSRect(x: 8, y: 6, width: 78, height: 16)
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)

        let slider = NSSlider(value: value, minValue: min, maxValue: max, target: self, action: action)
        slider.frame = NSRect(x: 88, y: 3, width: 140, height: 22)
        slider.isContinuous = true
        onCreate(slider)

        container.addSubview(label)
        container.addSubview(slider)

        let item = NSMenuItem()
        item.view = container
        return item
    }

    @objc private func toggleWindowMode() {
        useStandardWindow.toggle()
        UserDefaults.standard.set(useStandardWindow, forKey: "useStandardWindow")
        windowModeItem.state = useStandardWindow ? .on : .off
        captureCoordinator.setWindowMode(useStandardWindow ? .standard : .overlay)
    }
}
