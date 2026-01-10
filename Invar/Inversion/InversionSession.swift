//
//  InversionSession.swift
//  Invar
//

import AppKit
import CoreGraphics
import InvarCore
import QuartzCore

final class InversionSession: NSObject, NSWindowDelegate {
    private var region: CGRect
    private var screen: NSScreen
    private let displayWindow: InversionDisplayWindow
    private let onStop: () -> Void
    private lazy var controlWindow: InversionControlWindow = {
        InversionControlWindow(
            region: region,
            onClose: onStop,
            onMove: { [weak self] delta in
                self?.moveRegion(by: delta)
            }
        )
    }()
    private lazy var handleWindows: [CornerHandleWindow] = {
        [
            CornerHandleWindow(corner: .topLeft, onDrag: { [weak self] corner, delta in
                self?.resizeRegion(from: corner, by: delta)
            }),
            CornerHandleWindow(corner: .topRight, onDrag: { [weak self] corner, delta in
                self?.resizeRegion(from: corner, by: delta)
            }),
            CornerHandleWindow(corner: .bottomLeft, onDrag: { [weak self] corner, delta in
                self?.resizeRegion(from: corner, by: delta)
            }),
            CornerHandleWindow(corner: .bottomRight, onDrag: { [weak self] corner, delta in
                self?.resizeRegion(from: corner, by: delta)
            })
        ]
    }()
    private var keyMonitor: Any?
    private var globalKeyMonitor: Any?
    private let capture = ScreenCapture()
    private let inverter = ImageInverter()
    private let scheduler = FrameScheduler()
    private let captureQueue = DispatchQueue(label: "Invar.capture", qos: .userInitiated)
    private var inFlight = false
    private var isStopping = false
    private var settingsObserver: Any?

    init(region: CGRect, screen: NSScreen, mode: InversionWindowMode, onStop: @escaping () -> Void) {
        self.region = region
        self.screen = screen
        switch mode {
        case .overlay:
            self.displayWindow = InversionOverlayWindow(region: region)
        case .standard:
            self.displayWindow = InversionStandardWindow(region: region)
        }
        self.onStop = onStop
    }

    func start() {
        inverter.updateSettings(InversionSettings.current)
        displayWindow.present()
        if isOverlayMode {
            controlWindow.present()
            handleWindows.forEach { $0.present() }
            updateHandlePositions()
        } else {
            displayWindow.nsWindow.delegate = self
        }
        scheduler.onTick = { [weak self] in
            self?.tick()
        }
        scheduler.start()
        installKeyMonitors()
        installSettingsObserver()
    }

    func stop() {
        scheduler.stop()
        displayWindow.close()
        if isOverlayMode {
            controlWindow.close()
            handleWindows.forEach { $0.close() }
        }
        removeKeyMonitors()
        removeSettingsObserver()
    }

    private func tick() {
        guard !inFlight else { return }
        inFlight = true
        let startTime = CACurrentMediaTime()
        let windowNumber = displayWindow.nsWindow.windowNumber
        let windowID = windowNumber > 0 ? CGWindowID(windowNumber) : nil
        let captureRect = convertToCaptureCoordinates(region: region, screen: screen)

        captureQueue.async { [weak self] in
            guard let self else { return }
            let captured = self.capture.capture(region: captureRect, belowWindowID: windowID)
            let inverted = captured.flatMap { self.inverter.invert($0) }
            let duration = CACurrentMediaTime() - startTime

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.displayWindow.update(image: inverted)
                self.scheduler.recordFrame(duration: duration)
                self.inFlight = false
            }
        }
    }

    private func convertToCaptureCoordinates(region: CGRect, screen: NSScreen) -> CGRect {
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return region
        }

        let screenFrame = screen.frame
        let displayBounds = CGDisplayBounds(displayID)
        let pixelWidth = CGFloat(CGDisplayPixelsWide(displayID))
        let pixelHeight = CGFloat(CGDisplayPixelsHigh(displayID))
        let scaleX = pixelWidth / max(screenFrame.width, 1)
        let scaleY = pixelHeight / max(screenFrame.height, 1)
        let scale = (scaleX > 0 && scaleY > 0) ? min(scaleX, scaleY) : screen.backingScaleFactor

        let regionMinX = (region.minX - screenFrame.minX) * scale
        let regionMaxY = (region.maxY - screenFrame.minY) * scale

        let captureX = displayBounds.origin.x + regionMinX
        let captureY = displayBounds.origin.y + (pixelHeight - regionMaxY)
        let captureWidth = region.width * scale
        let captureHeight = region.height * scale

        return CGRect(x: captureX, y: captureY, width: captureWidth, height: captureHeight).integral
    }

    private func moveRegion(by delta: NSPoint) {
        var newOrigin = CGPoint(x: region.origin.x + delta.x, y: region.origin.y + delta.y)
        let bounds = screen.frame
        newOrigin.x = max(bounds.minX, min(newOrigin.x, bounds.maxX - region.width))
        newOrigin.y = max(bounds.minY, min(newOrigin.y, bounds.maxY - region.height))

        region.origin = newOrigin
        displayWindow.setFrame(region, display: true)
        if isOverlayMode {
            controlWindow.updatePosition(region: region)
            updateHandlePositions()
        }
    }

    private func resizeRegion(from corner: CornerHandle, by delta: NSPoint) {
        let minSize = CGSize(width: 80, height: 60)
        var newRegion = region

        switch corner {
        case .topLeft:
            newRegion.origin.x += delta.x
            newRegion.size.width -= delta.x
            newRegion.size.height += delta.y
        case .topRight:
            newRegion.size.width += delta.x
            newRegion.size.height += delta.y
        case .bottomLeft:
            newRegion.origin.x += delta.x
            newRegion.origin.y += delta.y
            newRegion.size.width -= delta.x
            newRegion.size.height -= delta.y
        case .bottomRight:
            newRegion.origin.y += delta.y
            newRegion.size.width += delta.x
            newRegion.size.height -= delta.y
        }

        if newRegion.size.width < minSize.width {
            let diff = minSize.width - newRegion.size.width
            if corner == .topLeft || corner == .bottomLeft {
                newRegion.origin.x -= diff
            }
            newRegion.size.width = minSize.width
        }
        if newRegion.size.height < minSize.height {
            let diff = minSize.height - newRegion.size.height
            if corner == .bottomLeft || corner == .bottomRight {
                newRegion.origin.y -= diff
            }
            newRegion.size.height = minSize.height
        }

        let bounds = screen.frame
        if newRegion.origin.x < bounds.minX {
            let deltaX = bounds.minX - newRegion.origin.x
            newRegion.origin.x += deltaX
            newRegion.size.width -= deltaX
        }
        if newRegion.origin.y < bounds.minY {
            let deltaY = bounds.minY - newRegion.origin.y
            newRegion.origin.y += deltaY
            newRegion.size.height -= deltaY
        }
        if newRegion.maxX > bounds.maxX {
            newRegion.size.width -= newRegion.maxX - bounds.maxX
        }
        if newRegion.maxY > bounds.maxY {
            newRegion.size.height -= newRegion.maxY - bounds.maxY
        }

        newRegion.size.width = max(minSize.width, newRegion.size.width)
        newRegion.size.height = max(minSize.height, newRegion.size.height)

        region = newRegion
        displayWindow.setFrame(region, display: true)
        if isOverlayMode {
            controlWindow.updatePosition(region: region)
            updateHandlePositions()
        }
    }

    private func updateHandlePositions() {
        handleWindows.forEach { $0.updatePosition(region: region) }
    }

    private var isOverlayMode: Bool {
        displayWindow is InversionOverlayWindow
    }

    private func installKeyMonitors() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.requestStop()
                return nil
            }
            return event
        }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.requestStop()
            }
        }
    }

    private func removeKeyMonitors() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
            self.globalKeyMonitor = nil
        }
    }

    private func installSettingsObserver() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: InversionSettings.notificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.inverter.updateSettings(InversionSettings.current)
        }
    }

    private func removeSettingsObserver() {
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
            self.settingsObserver = nil
        }
    }

    var currentRegion: CGRect { region }
    var currentScreen: NSScreen { screen }

    func windowDidMove(_ notification: Notification) {
        syncRegionFromWindow()
    }

    func windowDidResize(_ notification: Notification) {
        syncRegionFromWindow()
    }

    func windowWillClose(_ notification: Notification) {
        requestStop()
    }

    private func syncRegionFromWindow() {
        guard !isOverlayMode else { return }
        let frame = displayWindow.nsWindow.frame
        region = frame
        if let windowScreen = displayWindow.nsWindow.screen {
            screen = windowScreen
        }
    }

    private func requestStop() {
        guard !isStopping else { return }
        isStopping = true
        DispatchQueue.main.async { [weak self] in
            self?.onStop()
        }
    }
}
