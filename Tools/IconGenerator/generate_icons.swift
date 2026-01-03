#!/usr/bin/env swift
import AppKit
import Foundation

struct IconSpec {
    let size: Int
    let filename: String
}

struct Arguments {
    let output: URL
}

enum HalfFill {
    case left
    case right
}

let appIconSpecs: [IconSpec] = [
    IconSpec(size: 16, filename: "icon_16x16.png"),
    IconSpec(size: 32, filename: "icon_16x16@2x.png"),
    IconSpec(size: 32, filename: "icon_32x32.png"),
    IconSpec(size: 64, filename: "icon_32x32@2x.png"),
    IconSpec(size: 128, filename: "icon_128x128.png"),
    IconSpec(size: 256, filename: "icon_128x128@2x.png"),
    IconSpec(size: 256, filename: "icon_256x256.png"),
    IconSpec(size: 512, filename: "icon_256x256@2x.png"),
    IconSpec(size: 512, filename: "icon_512x512.png"),
    IconSpec(size: 1024, filename: "icon_512x512@2x.png"),
]

let panelIconSpecs: [IconSpec] = [
    IconSpec(size: 64, filename: "panel_64.png"),
    IconSpec(size: 128, filename: "panel_128.png"),
    IconSpec(size: 256, filename: "panel_256.png"),
]

let menuBarIconSpecs: [IconSpec] = [
    IconSpec(size: 16, filename: "menubar_16.png"),
    IconSpec(size: 32, filename: "menubar_16@2x.png"),
    IconSpec(size: 18, filename: "menubar_18.png"),
    IconSpec(size: 36, filename: "menubar_18@2x.png"),
    IconSpec(size: 20, filename: "menubar_20.png"),
    IconSpec(size: 40, filename: "menubar_20@2x.png"),
    IconSpec(size: 22, filename: "menubar_22.png"),
    IconSpec(size: 44, filename: "menubar_22@2x.png"),
    IconSpec(size: 24, filename: "menubar_24.png"),
    IconSpec(size: 48, filename: "menubar_24@2x.png"),
]

let statusBarLegacySpecs: [IconSpec] = [
    IconSpec(size: 16, filename: "statusbar_16.png"),
    IconSpec(size: 32, filename: "statusbar_16@2x.png"),
    IconSpec(size: 18, filename: "statusbar_18.png"),
    IconSpec(size: 36, filename: "statusbar_18@2x.png"),
    IconSpec(size: 20, filename: "statusbar_20.png"),
    IconSpec(size: 40, filename: "statusbar_20@2x.png"),
    IconSpec(size: 22, filename: "statusbar_22.png"),
    IconSpec(size: 44, filename: "statusbar_22@2x.png"),
    IconSpec(size: 24, filename: "statusbar_24.png"),
    IconSpec(size: 48, filename: "statusbar_24@2x.png"),
]

let permissionLegacySpecs: [IconSpec] = [
    IconSpec(size: 512, filename: "permission_512.png"),
    IconSpec(size: 1024, filename: "permission_512@2x.png"),
]

func parseArguments() -> Arguments? {
    var output: URL?

    var iterator = CommandLine.arguments.dropFirst().makeIterator()
    while let arg = iterator.next() {
        switch arg {
        case "--output":
            if let value = iterator.next() {
                output = URL(fileURLWithPath: value)
            }
        default:
            break
        }
    }

    guard let output else {
        return nil
    }

    return Arguments(output: output)
}

func snap(_ value: CGFloat) -> CGFloat {
    return CGFloat(Int(value.rounded()))
}

func drawLocalizedInvertSymbol(
    ctx: CGContext,
    rect: CGRect,
    strokeWidth: CGFloat,
    cornerRadius: CGFloat,
    foreground: CGColor,
    filledHalf: HalfFill
) {
    ctx.setLineWidth(strokeWidth)
    ctx.setStrokeColor(foreground)
    ctx.setFillColor(foreground)

    let symbolPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(symbolPath)
    ctx.clip()
    let halfRect: CGRect
    switch filledHalf {
    case .left:
        halfRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width / 2, height: rect.height)
    case .right:
        halfRect = CGRect(x: rect.midX, y: rect.minY, width: rect.width / 2, height: rect.height)
    }
    ctx.fill(halfRect)
    ctx.restoreGState()

    ctx.addPath(symbolPath)
    ctx.strokePath()
}

func renderIcon(size: CGFloat, foreground: NSColor, rectScale: CGFloat, strokeWidthPct: CGFloat, filledHalf: HalfFill) throws -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "GenerateIcons", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap context."])
    }

    NSGraphicsContext.saveGraphicsState()
    if let context = NSGraphicsContext(bitmapImageRep: rep) {
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        context.cgContext.setFillColor(NSColor.clear.cgColor)
        context.cgContext.fill(rect)

        let symbolSize = snap(size * rectScale)
        let symbolRect = CGRect(
            x: snap((size - symbolSize) / 2),
            y: snap((size - symbolSize) / 2),
            width: symbolSize,
            height: symbolSize
        )
        let strokeWidth = max(1, snap(size * strokeWidthPct))
        let cornerRadius = snap(symbolRect.height * 0.12)

        drawLocalizedInvertSymbol(
            ctx: context.cgContext,
            rect: symbolRect,
            strokeWidth: strokeWidth,
            cornerRadius: cornerRadius,
            foreground: foreground.cgColor,
            filledHalf: filledHalf
        )
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func writeIcons(specs: [IconSpec], output: URL, foreground: NSColor, rectScale: CGFloat, strokeWidthPct: CGFloat) throws {
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    for icon in specs {
        let rep = try renderIcon(
            size: CGFloat(icon.size),
            foreground: foreground,
            rectScale: rectScale,
            strokeWidthPct: strokeWidthPct,
            filledHalf: .left
        )
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "GenerateIcons", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG for \(icon.filename)."])
        }
        let destination = output.appendingPathComponent(icon.filename)
        try data.write(to: destination)
    }
}

func generateIcons(_ args: Arguments) throws {
    let menubarOutput = args.output.appendingPathComponent("menubar")
    let panelOutput = args.output.appendingPathComponent("panel")
    let appOutput = args.output.appendingPathComponent("app_icon")

    let statusBarOutput = args.output.appendingPathComponent("status_bar")
    let permissionOutput = args.output.appendingPathComponent("permission_icon")

    let menubarForeground = NSColor.white
    let panelForegroundLight = NSColor.white
    let panelForegroundDark = NSColor.white

    try writeIcons(specs: menuBarIconSpecs, output: menubarOutput, foreground: menubarForeground, rectScale: 0.70, strokeWidthPct: 0.08)
    try writeIcons(specs: statusBarLegacySpecs, output: statusBarOutput, foreground: menubarForeground, rectScale: 0.70, strokeWidthPct: 0.08)

    let panelLightOutput = panelOutput.appendingPathComponent("light")
    let panelDarkOutput = panelOutput.appendingPathComponent("dark")
    try writeIcons(specs: panelIconSpecs, output: panelLightOutput, foreground: panelForegroundLight, rectScale: 0.70, strokeWidthPct: 0.04)
    try writeIcons(specs: panelIconSpecs, output: panelDarkOutput, foreground: panelForegroundDark, rectScale: 0.70, strokeWidthPct: 0.04)

    try writeIcons(specs: permissionLegacySpecs, output: permissionOutput, foreground: panelForegroundLight, rectScale: 0.70, strokeWidthPct: 0.04)
    try writeIcons(specs: appIconSpecs, output: appOutput, foreground: panelForegroundLight, rectScale: 0.70, strokeWidthPct: 0.04)
}

guard let args = parseArguments() else {
    fputs("Usage: generate_icons.swift --output <dir>\n", stderr)
    exit(1)
}

do {
    try generateIcons(args)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
