//
//  StatusBarController.swift
//  Invar
//

import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private var selectionWindow: SelectionOverlayWindow?
    private var selectedRegion: CGRect?
    private var selectedScreen: NSScreen?
    private let screenCapture = ScreenCapture()
    private var inversionSession: InversionSession?
    private var useStandardWindow = UserDefaults.standard.bool(forKey: "useStandardWindow")
    private var contrastSlider: NSSlider?
    private var brightnessSlider: NSSlider?
    private var gammaSlider: NSSlider?
    private var permissionPanel: ScreenRecordingPermissionPanel?
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

    init() {
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
        guard let screen = screenUnderMouse() else {
            print("Select region failed: no screen found for mouse location.")
            return
        }
        if !screenCapture.hasPermission() {
            showScreenRecordingPermissionPanel()
            return
        }
        if let selectionWindow {
            selectionWindow.close()
            self.selectionWindow = nil
        }

        let window = SelectionOverlayWindow(
            screen: screen,
            onSelection: { [weak self] rect in
                guard let self else { return }
                self.selectedRegion = rect
                self.selectedScreen = screen
                print("Selected region: \(rect)")
                DispatchQueue.main.async { [weak self] in
                    self?.selectionWindow?.close()
                    self?.selectionWindow = nil
                }
                self.startInversionIfPossible()
            },
            onCancel: { [weak self] in
                print("Selection cancelled")
                DispatchQueue.main.async { [weak self] in
                    self?.selectionWindow?.close()
                    self?.selectionWindow = nil
                }
            }
        )
        selectionWindow = window
        window.present()
    }

    func beginRegionSelection() {
        selectRegion()
    }

    @objc private func disableInversion() {
        inversionSession?.stop()
        inversionSession = nil
    }

    @objc private func quit() {
        print("Quit requested")
        NSApp.terminate(nil)
    }

    private func screenUnderMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func showScreenRecordingPermissionPanel() {
        guard permissionPanel == nil else { return }
        permissionPanel = ScreenRecordingPermissionPanel(
            showsOpenSettings: true,
            onRequestAccess: { [weak self] in
                _ = self?.screenCapture.requestPermission()
                self?.permissionPanel = nil
            },
            onCancel: { [weak self] in
                self?.permissionPanel = nil
            }
        )
        permissionPanel?.show()
    }

    private func startInversionIfPossible() {
        guard let selectedRegion, let selectedScreen else {
            showAlert(title: "No Region Selected", message: "Select a region before enabling inversion.")
            return
        }

        if inversionSession != nil {
            inversionSession?.stop()
            inversionSession = nil
        }

        let hasAccess = screenCapture.hasPermission()
        if !hasAccess {
            return
        }

        let mode: InversionWindowMode = useStandardWindow ? .standard : .overlay
        let session = InversionSession(region: selectedRegion, screen: selectedScreen, mode: mode) { [weak self] in
            self?.disableInversion()
        }
        inversionSession = session
        session.start()
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

        if let session = inversionSession {
            selectedRegion = session.currentRegion
            selectedScreen = session.currentScreen
            session.stop()
            inversionSession = nil
            startInversionIfPossible()
        }
    }
}
